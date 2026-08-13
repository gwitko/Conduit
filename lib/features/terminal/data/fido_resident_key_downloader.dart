import 'dart:convert';
import 'dart:typed_data';

import 'package:cbor/cbor.dart';
import 'package:crypto/crypto.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:fido2/fido2_client.dart';

import 'openssh_security_key_signer.dart';
import 'ssh_error_formatter.dart';

/// A resident (discoverable) OpenSSH credential read off a FIDO2
/// authenticator, equivalent to one entry of `ssh-keygen -K`.
class ResidentSecurityKey {
  const ResidentSecurityKey({required this.keyPair, this.userName});

  final OpenSSHSecurityKeyPair keyPair;
  final String? userName;

  String get application => keyPair.application;

  String get algorithm =>
      keyPair is OpenSSHSecurityKeyEd25519KeyPair ? 'ed25519-sk' : 'ecdsa-sk';

  bool get requiresUserVerification => keyPair.flags & 0x04 != 0;

  String get fingerprintSha256 {
    final digest = sha256.convert(keyPair.toPublicKey().encode()).bytes;
    return 'SHA256:${base64.encode(digest).replaceAll('=', '')}';
  }

  /// A label suggestion for the imported key: the application suffix after
  /// `ssh:` when present, otherwise the (non-default) user name.
  String get suggestedLabel {
    final app = application.startsWith('ssh:')
        ? application.substring(4).trim()
        : application.trim();
    if (app.isNotEmpty) {
      return app;
    }
    final name = userName?.trim() ?? '';
    // ssh-keygen enrolls resident keys with the fixed user name "openssh",
    // which carries no information worth showing.
    if (name.isNotEmpty && name != 'openssh') {
      return name;
    }
    return '';
  }

  String toPem() => keyPair.toPem();
}

class ResidentKeyDownloadCancelled implements Exception {
  const ResidentKeyDownloadCancelled();
}

class ResidentKeyDownloadError implements Exception {
  const ResidentKeyDownloadError(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Downloads resident OpenSSH credentials from a FIDO2 authenticator using
/// CTAP2 credential management, like `ssh-keygen -K` does on desktop.
///
/// The private part never leaves the authenticator: the produced stubs only
/// contain the public key, application and credential handle.
class FidoResidentKeyDownloader {
  const FidoResidentKeyDownloader({
    required this.openDevice,
    this.closeDevice,
    this.onStatus,
    this.onPinRequest,
  });

  final CtapDeviceOpener openDevice;
  final CtapDeviceCloser? closeDevice;
  final SecurityKeyStatusHandler? onStatus;
  final SecurityKeyPinRequester? onPinRequest;

  static const _credentialManagementPreviewCommand = 0x41;
  static const _sshApplicationPrefix = 'ssh:';
  static const _maxPinAttempts = 3;

  Future<List<ResidentSecurityKey>> download() async {
    String? pin;
    int? pinRetriesRemaining;
    var pinAttempts = 0;

    while (true) {
      // NFC sessions cannot survive a PIN dialog on iOS, so the PIN has to
      // be collected before the session opens. Reading resident keys always
      // needs the PIN, so collect it up front everywhere for one less
      // round-trip on rejection.
      pin ??= await _promptForPin(retriesRemaining: pinRetriesRemaining);

      onStatus?.call('Waiting for hardware key over USB or NFC...');
      final device = await openDevice();
      var ok = false;
      try {
        final ctap = await Ctap2.create(device);
        final command = _credentialManagementCommandFor(ctap.info);
        final pinProtocol = _pinProtocolFor(ctap.info);
        final clientPin = ClientPin(ctap, pinProtocol: pinProtocol);

        final List<int> pinToken;
        try {
          pinToken = await clientPin.getPinToken(
            pin,
            permissions: [ClientPinPermission.credentialManagement],
          );
        } on CtapError catch (error) {
          if (error.status != CtapStatusCode.ctap2ErrPinInvalid) {
            onStatus?.call(describeCtapStatus(error.status));
            rethrow;
          }
          pin = null;
          pinAttempts++;
          pinRetriesRemaining = await _pinRetries(clientPin);
          final outOfRetries =
              pinRetriesRemaining != null && pinRetriesRemaining <= 0;
          if (pinAttempts >= _maxPinAttempts || outOfRetries) {
            onStatus?.call(describeCtapStatus(error.status));
            rethrow;
          }
          onStatus?.call('Security key PIN was incorrect. Try again.');
          continue;
        }

        onStatus?.call('Reading resident keys from the security key...');
        final credentials = _CredentialManagementClient(
          device: device,
          command: command,
          pinProtocol: pinProtocol,
          pinToken: pinToken,
        );
        final keys = await _readSshKeys(credentials);
        ok = true;
        onStatus?.call(
          keys.isEmpty
              ? 'No resident SSH keys found on this security key.'
              : 'Found ${keys.length} resident SSH '
                    '${keys.length == 1 ? 'key' : 'keys'}.',
        );
        return keys;
      } finally {
        await closeDevice?.call(device, ok);
      }
    }
  }

  Future<List<ResidentSecurityKey>> _readSshKeys(
    _CredentialManagementClient credentials,
  ) async {
    final keys = <ResidentSecurityKey>[];
    for (final rp in await credentials.enumerateRps()) {
      final rpId = rp.rp.id;
      if (!rpId.startsWith(_sshApplicationPrefix)) {
        continue;
      }
      for (final credential in await credentials.enumerateCredentials(
        rp.rpIdHash,
      )) {
        final key = _toResidentKey(rpId, credential);
        if (key != null) {
          keys.add(key);
        }
      }
    }
    return keys;
  }

  ResidentSecurityKey? _toResidentKey(String rpId, CmCredential credential) {
    // Mirrors OpenSSH sk-usbhid.c: resident keys are marked as such, always
    // require user presence, and require user verification when the
    // credential was created with credProtect uvRequired (0x03).
    var flags = 0x01 | 0x20;
    if (credential.credProtect == 0x03) {
      flags |= 0x04;
    }
    final keyHandle = Uint8List.fromList(credential.credentialId.id);
    final publicKey = credential.publicKey;

    final OpenSSHSecurityKeyPair keyPair;
    if (publicKey is EdDSA &&
        publicKey[CoseKey.okpCrvIdx] == CoseKey.okpCrvEd25519) {
      keyPair = OpenSSHSecurityKeyEd25519KeyPair(
        publicKey: Uint8List.fromList(
          (publicKey[CoseKey.okpXIdx] as List).cast<int>(),
        ),
        application: rpId,
        flags: flags,
        keyHandle: keyHandle,
        reserved: '',
      );
    } else if (publicKey is ES256 &&
        publicKey[CoseKey.ec2CrvIdx] == CoseKey.ec2CrvP256) {
      keyPair = OpenSSHSecurityKeyEcdsaKeyPair(
        q: _uncompressedPoint(
          (publicKey[CoseKey.ec2XIdx] as List).cast<int>(),
          (publicKey[CoseKey.ec2YIdx] as List).cast<int>(),
        ),
        application: rpId,
        flags: flags,
        keyHandle: keyHandle,
        reserved: '',
      );
    } else {
      return null;
    }
    return ResidentSecurityKey(
      keyPair: keyPair,
      userName: credential.user.name,
    );
  }

  static Uint8List _uncompressedPoint(List<int> x, List<int> y) {
    return Uint8List.fromList([
      0x04,
      ...List<int>.filled(32 - x.length, 0),
      ...x,
      ...List<int>.filled(32 - y.length, 0),
      ...y,
    ]);
  }

  int _credentialManagementCommandFor(AuthenticatorInfo info) {
    final options = info.options;
    if (options?['credMgmt'] == true) {
      return Ctap2Commands.credentialManagement.value;
    }
    if (options?['credentialMgmtPreview'] == true) {
      return _credentialManagementPreviewCommand;
    }
    const message =
        'This security key cannot list resident keys. Downloading them '
        'needs CTAP2 credential management support on the key.';
    onStatus?.call(message);
    throw const ResidentKeyDownloadError(message);
  }

  Future<String> _promptForPin({int? retriesRemaining}) async {
    final pinRequest = onPinRequest;
    if (pinRequest == null) {
      throw StateError('Security key PIN is required.');
    }
    final pin = await pinRequest(retriesRemaining: retriesRemaining);
    if (pin == null || pin.isEmpty) {
      throw const ResidentKeyDownloadCancelled();
    }
    return pin;
  }

  Future<int?> _pinRetries(ClientPin clientPin) async {
    try {
      return await clientPin.getPinRetries();
    } catch (_) {
      return null;
    }
  }

  PinProtocol _pinProtocolFor(AuthenticatorInfo info) {
    final protocols = info.pinUvAuthProtocols;
    if (protocols == null || protocols.isEmpty) {
      return PinProtocolV1();
    }
    if (protocols.contains(2)) {
      return PinProtocolV2();
    }
    if (protocols.contains(1)) {
      return PinProtocolV1();
    }
    throw StateError('Unsupported security key PIN protocol.');
  }
}

/// Speaks authenticatorCredentialManagement directly on a [CtapDevice] so the
/// same code paths serve both the CTAP 2.1 command (0x0A) and the widely
/// deployed "credentialMgmtPreview" variant (0x41), which shares the wire
/// format but not the command byte. The fido2 package only issues 0x0A.
class _CredentialManagementClient {
  const _CredentialManagementClient({
    required this.device,
    required this.command,
    required this.pinProtocol,
    required this.pinToken,
  });

  final CtapDevice device;
  final int command;
  final PinProtocol pinProtocol;
  final List<int> pinToken;

  Future<List<CmRp>> enumerateRps() async {
    final first = await _invoke(
      CredentialManagementSubCommand.enumerateRpsBegin.value,
      allowNoCredentials: true,
    );
    if (first == null || first.rp == null) {
      return [];
    }
    final rps = <CmRp>[
      CmRp(rp: first.rp!, rpIdHash: first.rpIdHash!, totalRPs: first.totalRPs),
    ];
    final total = first.totalRPs ?? 1;
    while (rps.length < total) {
      final next = await _invoke(
        CredentialManagementSubCommand.enumerateRpsGetNextRp.value,
        auth: false,
      );
      rps.add(CmRp(rp: next!.rp!, rpIdHash: next.rpIdHash!));
    }
    return rps;
  }

  Future<List<CmCredential>> enumerateCredentials(List<int> rpIdHash) async {
    final first = await _invoke(
      CredentialManagementSubCommand.enumerateCredentialsBegin.value,
      params: {
        CredentialManagementSubCommandParams.rpIdHash.value: CborBytes(
          rpIdHash,
        ),
      },
      allowNoCredentials: true,
    );
    if (first == null || first.credentialId == null) {
      return [];
    }
    final credentials = <CmCredential>[_credentialOf(first)];
    final total = first.totalCredentials ?? 1;
    while (credentials.length < total) {
      final next = await _invoke(
        CredentialManagementSubCommand
            .enumerateCredentialsGetNextCredential
            .value,
        auth: false,
      );
      credentials.add(_credentialOf(next!));
    }
    return credentials;
  }

  static CmCredential _credentialOf(CredentialManagementResponse response) {
    return CmCredential(
      user: response.user!,
      credentialId: response.credentialId!,
      publicKey: response.publicKey!,
      totalCredentials: response.totalCredentials,
      credProtect: response.credProtect ?? 0x01,
      largeBlobKey: response.largeBlobKey,
    );
  }

  Future<CredentialManagementResponse?> _invoke(
    int subCommand, {
    Map<int, dynamic>? params,
    bool auth = true,
    bool allowNoCredentials = false,
  }) async {
    CborMap? paramsMap;
    if (params != null) {
      paramsMap = CborMap.fromEntries(
        params.entries.map(
          (entry) => MapEntry(CborSmallInt(entry.key), CborValue(entry.value)),
        ),
      );
    }

    List<int>? pinUvAuthParam;
    if (auth) {
      final message = <int>[
        subCommand,
        if (paramsMap != null) ...cbor.encode(paramsMap),
      ];
      final mac = await pinProtocol.authenticate(pinToken, message);
      // PIN protocol 1 sends LEFT(HMAC, 16); protocol 2 sends the full HMAC.
      pinUvAuthParam = pinProtocol.version == 1 ? mac.sublist(0, 16) : mac;
    }

    final request = CredentialManagementRequest(
      subCommand: subCommand,
      params: paramsMap,
      pinUvAuthProtocol: auth ? pinProtocol.version : null,
      pinUvAuthParam: pinUvAuthParam,
    ).encode();
    final response = await device.transceive([command, ...request.skip(1)]);

    if (allowNoCredentials &&
        response.status == CtapStatusCode.ctap2ErrNoCredentials.value) {
      return null;
    }
    if (response.status != CtapStatusCode.ctap1ErrSuccess.value) {
      throw CtapError.fromCode(response.status);
    }
    return response.data.isEmpty
        ? null
        : CredentialManagementResponse.decode(response.data);
  }
}

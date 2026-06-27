import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:dartssh2/dartssh2.dart';
import 'package:fido2/fido2_client.dart';
import 'package:flutter/services.dart';

import 'fido_nfc_ctap_device.dart';
import 'fido_usb_ctap_device.dart';
import 'ssh_error_formatter.dart';

typedef CtapDeviceOpener = Future<CtapDevice> Function();
typedef CtapDeviceCloser = Future<void> Function(CtapDevice device, bool ok);
typedef SecurityKeyStatusHandler = void Function(String message);
typedef SecurityKeyPinRequester =
    Future<String?> Function({int? retriesRemaining});

class OpenSshSecurityKeySigner {
  const OpenSshSecurityKeySigner({
    required this.openDevice,
    this.closeDevice,
    this.onStatus,
    this.onPinRequest,
  });

  final CtapDeviceOpener openDevice;
  final CtapDeviceCloser? closeDevice;
  final SecurityKeyStatusHandler? onStatus;
  final SecurityKeyPinRequester? onPinRequest;

  List<SSHKeyPair> attach(List<SSHKeyPair> keyPairs) {
    return [
      for (final keyPair in keyPairs)
        switch (keyPair) {
          OpenSSHSecurityKeyEcdsaKeyPair() => OpenSSHSecurityKeyEcdsaKeyPair(
            q: keyPair.q,
            application: keyPair.application,
            flags: keyPair.flags,
            keyHandle: keyPair.keyHandle,
            reserved: keyPair.reserved,
            signer: (data) => _signEcdsa(keyPair, data),
          ),
          OpenSSHSecurityKeyEd25519KeyPair() =>
            OpenSSHSecurityKeyEd25519KeyPair(
              publicKey: keyPair.publicKey,
              application: keyPair.application,
              flags: keyPair.flags,
              keyHandle: keyPair.keyHandle,
              reserved: keyPair.reserved,
              signer: (data) => _signEd25519(keyPair, data),
            ),
          _ => keyPair,
        },
    ];
  }

  Future<SSHSecurityKeyEcdsaSignature> _signEcdsa(
    OpenSSHSecurityKeyEcdsaKeyPair keyPair,
    Uint8List data,
  ) async {
    final assertion = await _getAssertion(keyPair, data);
    final (r, s) = _decodeDerEcdsaSignature(assertion.signature);
    final (flags, counter) = _parseAuthenticatorData(assertion.authData);
    return SSHSecurityKeyEcdsaSignature(
      r: r,
      s: s,
      flags: flags,
      counter: counter,
    );
  }

  Future<SSHSecurityKeyEd25519Signature> _signEd25519(
    OpenSSHSecurityKeyEd25519KeyPair keyPair,
    Uint8List data,
  ) async {
    final assertion = await _getAssertion(keyPair, data);
    final (flags, counter) = _parseAuthenticatorData(assertion.authData);
    return SSHSecurityKeyEd25519Signature(
      signature: Uint8List.fromList(assertion.signature),
      flags: flags,
      counter: counter,
    );
  }

  Future<GetAssertionResponse> _getAssertion(
    OpenSSHSecurityKeyPair keyPair,
    Uint8List data,
  ) async {
    final clientDataHash = crypto.sha256.convert(data).bytes;

    var collectPinUpFront =
        Platform.isIOS && _requiresUserVerification(keyPair.flags);
    String? presetPin;
    int? pinRetriesRemaining;
    var pinAttempts = 0;
    var nfcRetried = false;
    const maxPinAttempts = 3;

    while (true) {
      if (collectPinUpFront) {
        presetPin = await _promptForPin(retriesRemaining: pinRetriesRemaining);
      }

      onStatus?.call('Waiting for hardware key over USB or NFC...');
      final device = await openDevice();
      var ok = false;
      try {
        final request = await _buildAssertionRequest(
          device: device,
          keyPair: keyPair,
          clientDataHash: clientDataHash,
          presetPin: presetPin,
        );
        onStatus?.call(_interactionMessage(device));
        var response = await device.transceive(request.encode());
        if (response.status == CtapStatusCode.ctap2ErrPuatRequired.value &&
            request.pinAuth == null) {
          if (Platform.isIOS) {
            collectPinUpFront = true;
            continue;
          }
          final pinRequest = await _buildAssertionRequest(
            device: device,
            keyPair: keyPair,
            clientDataHash: clientDataHash,
            forceUserVerification: true,
          );
          onStatus?.call(_interactionMessage(device));
          response = await device.transceive(pinRequest.encode());
        }
        if (response.status != CtapStatusCode.ctap1ErrSuccess.value) {
          final error = CtapError.fromCode(response.status);
          onStatus?.call(describeCtapStatus(error.status));
          throw error;
        }
        ok = true;
        onStatus?.call('Hardware key accepted.');
        return GetAssertionResponse.decode(response.data);
      } on _PinRejected catch (rejection) {
        pinAttempts++;
        pinRetriesRemaining = rejection.retriesRemaining;
        presetPin = null;
        collectPinUpFront = true;
        final outOfRetries =
            pinRetriesRemaining != null && pinRetriesRemaining <= 0;
        if (pinAttempts >= maxPinAttempts || outOfRetries) {
          onStatus?.call(describeCtapStatus(rejection.error.status));
          throw rejection.error;
        }
        onStatus?.call('Security key PIN was incorrect. Try again.');
        continue;
      } catch (error) {
        if (!nfcRetried && _shouldRetryNfc(device, error)) {
          nfcRetried = true;
          onStatus?.call(
            'NFC read was interrupted. Keep the key still near the phone; '
            'retrying...',
          );
          continue;
        }
        rethrow;
      } finally {
        await closeDevice?.call(device, ok);
      }
    }
  }

  Future<GetAssertionRequest> _buildAssertionRequest({
    required CtapDevice device,
    required OpenSSHSecurityKeyPair keyPair,
    required List<int> clientDataHash,
    bool forceUserVerification = false,
    String? presetPin,
  }) async {
    final requiresUserVerification =
        forceUserVerification ||
        presetPin != null ||
        _requiresUserVerification(keyPair.flags);
    final pinAuth = requiresUserVerification
        ? await _pinAuthFor(
            device: device,
            clientDataHash: clientDataHash,
            rpId: keyPair.application,
            presetPin: presetPin,
          )
        : null;

    return GetAssertionRequest(
      rpId: keyPair.application,
      clientDataHash: clientDataHash,
      allowList: [
        PublicKeyCredentialDescriptor(
          type: 'public-key',
          id: keyPair.keyHandle,
        ),
      ],
      options: {'up': true},
      pinAuth: pinAuth?.authParam,
      pinProtocol: pinAuth?.protocolVersion,
    );
  }

  Future<String> _promptForPin({int? retriesRemaining}) async {
    final pinRequest = onPinRequest;
    if (pinRequest == null) {
      throw StateError('Security key PIN is required.');
    }
    onStatus?.call('Security key PIN required.');
    final pin = await pinRequest(retriesRemaining: retriesRemaining);
    if (pin == null || pin.isEmpty) {
      throw StateError('Security key PIN entry was cancelled.');
    }
    return pin;
  }

  Future<_PinAuth> _pinAuthFor({
    required CtapDevice device,
    required List<int> clientDataHash,
    required String rpId,
    String? presetPin,
  }) async {
    final ctap = await Ctap2.create(device);
    final pinProtocol = _pinProtocolFor(ctap.info);
    final clientPin = ClientPin(ctap, pinProtocol: pinProtocol);

    if (presetPin != null) {
      try {
        final token = await clientPin.getPinToken(
          presetPin,
          permissions: [ClientPinPermission.getAssertion],
          permissionsRpId: rpId,
        );
        onStatus?.call('Security key PIN accepted.');
        final auth = await pinProtocol.authenticate(token, clientDataHash);
        return _PinAuth(authParam: auth, protocolVersion: pinProtocol.version);
      } on CtapError catch (error) {
        if (error.status == CtapStatusCode.ctap2ErrPinInvalid) {
          throw _PinRejected(error, await _pinRetries(clientPin));
        }
        rethrow;
      }
    }

    final pinRequest = onPinRequest;
    if (pinRequest == null) {
      throw StateError('Security key PIN is required.');
    }

    for (var attempt = 0; attempt < 3; attempt++) {
      final retriesRemaining = await _pinRetries(clientPin);
      onStatus?.call('Security key PIN required.');
      final pin = await pinRequest(retriesRemaining: retriesRemaining);
      if (pin == null || pin.isEmpty) {
        throw StateError('Security key PIN entry was cancelled.');
      }

      try {
        final token = await clientPin.getPinToken(
          pin,
          permissions: [ClientPinPermission.getAssertion],
          permissionsRpId: rpId,
        );
        onStatus?.call('Security key PIN accepted.');
        final auth = await pinProtocol.authenticate(token, clientDataHash);
        return _PinAuth(authParam: auth, protocolVersion: pinProtocol.version);
      } on CtapError catch (error) {
        if (error.status == CtapStatusCode.ctap2ErrPinInvalid && attempt < 2) {
          onStatus?.call('Security key PIN was incorrect.');
          continue;
        }
        rethrow;
      }
    }

    throw StateError('Security key PIN could not be verified.');
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

  static String _interactionMessage(CtapDevice device) {
    if (device is FidoUsbCtapDevice) {
      return 'Touch your USB security key.';
    }
    if (device is FidoNfcCtapDevice) {
      return 'Keep your NFC security key held against the phone.';
    }
    return 'Touch your USB key, or hold your NFC key near the phone.';
  }

  static bool _shouldRetryNfc(CtapDevice device, Object error) {
    if (device is! FidoNfcCtapDevice) {
      return false;
    }
    if (error is PlatformException) {
      return error.code == '500' || error.code == '503' || error.code == '406';
    }
    return false;
  }

  static bool _requiresUserVerification(int flags) => flags & 0x04 != 0;

  static (int, int) _parseAuthenticatorData(List<int> authData) {
    if (authData.length < 37) {
      throw const FormatException('Authenticator data was too short.');
    }
    final flags = authData[32];
    final counter = ByteData.sublistView(
      Uint8List.fromList(authData),
      33,
      37,
    ).getUint32(0);
    return (flags, counter);
  }

  static (BigInt, BigInt) _decodeDerEcdsaSignature(List<int> signature) {
    final reader = _DerReader(signature);
    reader.expect(0x30);
    final sequenceLength = reader.readLength();
    final sequenceEnd = reader.offset + sequenceLength;
    final r = reader.readInteger();
    final s = reader.readInteger();
    if (reader.offset != sequenceEnd || sequenceEnd != signature.length) {
      throw const FormatException('Malformed DER ECDSA signature.');
    }
    return (r, s);
  }
}

class _PinAuth {
  const _PinAuth({required this.authParam, required this.protocolVersion});

  final List<int> authParam;
  final int protocolVersion;
}

class _PinRejected implements Exception {
  const _PinRejected(this.error, this.retriesRemaining);

  final CtapError error;
  final int? retriesRemaining;
}

class _DerReader {
  _DerReader(List<int> bytes) : _bytes = bytes;

  final List<int> _bytes;
  int offset = 0;

  void expect(int byte) {
    if (offset >= _bytes.length || _bytes[offset] != byte) {
      throw const FormatException('Malformed DER ECDSA signature.');
    }
    offset++;
  }

  int readLength() {
    if (offset >= _bytes.length) {
      throw const FormatException('Malformed DER ECDSA signature.');
    }
    final first = _bytes[offset++];
    if (first & 0x80 == 0) {
      return first;
    }
    final lengthBytes = first & 0x7f;
    if (lengthBytes == 0 || lengthBytes > 4) {
      throw const FormatException('Malformed DER ECDSA signature.');
    }
    var length = 0;
    for (var i = 0; i < lengthBytes; i++) {
      if (offset >= _bytes.length) {
        throw const FormatException('Malformed DER ECDSA signature.');
      }
      length = (length << 8) | _bytes[offset++];
    }
    return length;
  }

  BigInt readInteger() {
    expect(0x02);
    final length = readLength();
    if (length <= 0 || offset + length > _bytes.length) {
      throw const FormatException('Malformed DER ECDSA signature.');
    }
    final valueBytes = _bytes.sublist(offset, offset + length);
    offset += length;

    var value = BigInt.zero;
    for (final byte in valueBytes) {
      value = (value << 8) | BigInt.from(byte);
    }
    return value;
  }
}

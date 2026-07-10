import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:dartssh2/dartssh2.dart';
import 'package:fido2/fido2_client.dart';
import 'package:flutter/services.dart';

import '../domain/security_key_interaction.dart';
import 'fido_nfc_ctap_device.dart';
import 'fido_usb_ctap_device.dart';
import 'ssh_error_formatter.dart';

typedef CtapDeviceOpener = Future<CtapDevice> Function();
typedef CtapDeviceCloser = Future<void> Function(CtapDevice device, bool ok);
typedef SecurityKeyStatusHandler = void Function(String message);
typedef SecurityKeyPinRequester =
    Future<String?> Function({int? retriesRemaining});
typedef SecurityKeySelector =
    Future<SecurityKeySelection?> Function(List<String> labels);

class OpenSshSecurityKeySigner {
  const OpenSshSecurityKeySigner({
    required this.openDevice,
    this.closeDevice,
    this.onStatus,
    this.onPinRequest,
    this.onKeySelect,
  });

  final CtapDeviceOpener openDevice;
  final CtapDeviceCloser? closeDevice;
  final SecurityKeyStatusHandler? onStatus;
  final SecurityKeyPinRequester? onPinRequest;
  final SecurityKeySelector? onKeySelect;

  List<SSHKeyPair> attach(List<SSHKeyPair> keyPairs, {List<String>? labels}) {
    assert(labels == null || labels.length == keyPairs.length);
    final session = _SecurityKeySession();
    final attached = <SSHKeyPair>[];
    for (var i = 0; i < keyPairs.length; i++) {
      final keyPair = keyPairs[i];
      switch (keyPair) {
        case OpenSSHSecurityKeyEcdsaKeyPair():
          final entry = _register(session, keyPair, labels?[i]);
          attached.add(
            OpenSSHSecurityKeyEcdsaKeyPair(
              q: keyPair.q,
              application: keyPair.application,
              flags: keyPair.flags,
              keyHandle: keyPair.keyHandle,
              reserved: keyPair.reserved,
              signer: (data) => _signEcdsa(entry, session, data),
            ),
          );
        case OpenSSHSecurityKeyEd25519KeyPair():
          final entry = _register(session, keyPair, labels?[i]);
          attached.add(
            OpenSSHSecurityKeyEd25519KeyPair(
              publicKey: keyPair.publicKey,
              application: keyPair.application,
              flags: keyPair.flags,
              keyHandle: keyPair.keyHandle,
              reserved: keyPair.reserved,
              signer: (data) => _signEd25519(entry, session, data),
            ),
          );
        default:
          attached.add(keyPair);
      }
    }
    return attached;
  }

  _SecurityKeyEntry _register(
    _SecurityKeySession session,
    OpenSSHSecurityKeyPair keyPair,
    String? label,
  ) {
    final effectiveLabel = label == null || label.trim().isEmpty
        ? 'hardware key ${session.entries.length + 1}'
        : label.trim();
    final entry = _SecurityKeyEntry(keyPair: keyPair, label: effectiveLabel);
    session.entries.add(entry);
    return entry;
  }

  Future<SSHSecurityKeyEcdsaSignature> _signEcdsa(
    _SecurityKeyEntry entry,
    _SecurityKeySession session,
    Uint8List data,
  ) async {
    final assertion = await _getAssertion(entry, session, data);
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
    _SecurityKeyEntry entry,
    _SecurityKeySession session,
    Uint8List data,
  ) async {
    final assertion = await _getAssertion(entry, session, data);
    final (flags, counter) = _parseAuthenticatorData(assertion.authData);
    return SSHSecurityKeyEd25519Signature(
      signature: Uint8List.fromList(assertion.signature),
      flags: flags,
      counter: counter,
    );
  }

  Future<GetAssertionResponse> _getAssertion(
    _SecurityKeyEntry entry,
    _SecurityKeySession session,
    Uint8List data,
  ) async {
    final selected = await _selectedEntry(session);
    if (selected != null && !identical(selected, entry)) {
      throw SSHSecurityKeyNotPresentError(
        '"${entry.label}" was not the selected security key.',
        preferredPublicKey: selected.keyPair.toPublicKey().encode(),
      );
    }

    if (session.isKnownAbsent(entry)) {
      throw _mismatchError(entry, session, announce: false);
    }

    final keyPair = entry.keyPair;
    final clientDataHash = crypto.sha256.convert(data).bytes;
    final selectionActive = selected != null;

    var collectPinUpFront =
        Platform.isIOS && _requiresUserVerification(keyPair.flags);
    String? presetPin;
    var presetPinFromCache = false;
    int? pinRetriesRemaining;
    var pinAttempts = 0;
    var wrongKeyAttempts = 0;
    var nfcRetried = false;
    const maxPinAttempts = 3;
    const maxWrongKeyAttempts = 3;

    while (true) {
      if (collectPinUpFront) {
        final cachedPin = session.cachedPin;
        presetPinFromCache = cachedPin != null;
        presetPin =
            cachedPin ??
            await _promptForPin(retriesRemaining: pinRetriesRemaining);
      }

      onStatus?.call(_waitingMessage(session));
      final device = await openDevice();
      var ok = false;
      try {
        if (!entry.requiresUserVerification) {
          await _checkPresence(
            device,
            entry,
            session,
            clientDataHash,
            selectionActive: selectionActive,
          );
        } else if (!selectionActive &&
            presetPin == null &&
            session.cachedPin == null &&
            !session.hasFreshResult(entry) &&
            session.entries.length > 1) {
          await _identifyPresentedKey(device, entry, session, clientDataHash);
        }
        var request = await _buildAssertionRequest(
          device: device,
          session: session,
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
          request = await _buildAssertionRequest(
            device: device,
            session: session,
            keyPair: keyPair,
            clientDataHash: clientDataHash,
            forceUserVerification: true,
          );
          onStatus?.call(_interactionMessage(device));
          response = await device.transceive(request.encode());
        }
        if (response.status == CtapStatusCode.ctap2ErrNoCredentials.value) {
          session.record(entry, present: false);
          if (selectionActive) {
            throw const _WrongKeyPresented();
          }
          await _probeSiblings(
            device,
            entry,
            session,
            clientDataHash,
            pinAuth: request.pinAuth,
            pinProtocol: request.pinProtocol,
          );
          throw _mismatchError(entry, session);
        }
        if (response.status != CtapStatusCode.ctap1ErrSuccess.value) {
          final error = CtapError.fromCode(response.status);
          onStatus?.call(describeCtapStatus(error.status));
          throw error;
        }
        ok = true;
        session.record(entry, present: true);
        onStatus?.call('Hardware key accepted.');
        return GetAssertionResponse.decode(response.data);
      } on _PinRejected catch (rejection) {
        pinRetriesRemaining = rejection.retriesRemaining;
        presetPin = null;
        collectPinUpFront = true;
        final rejectedCachedPin = presetPinFromCache;
        presetPinFromCache = false;
        if (!rejectedCachedPin) {
          pinAttempts++;
        }
        final outOfRetries =
            pinRetriesRemaining != null && pinRetriesRemaining <= 0;
        if (pinAttempts >= maxPinAttempts || outOfRetries) {
          onStatus?.call(describeCtapStatus(rejection.error.status));
          throw rejection.error;
        }
        onStatus?.call(
          rejectedCachedPin
              ? 'Enter the PIN for this security key.'
              : 'Security key PIN was incorrect. Try again.',
        );
        continue;
      } on _WrongKeyPresented {
        wrongKeyAttempts++;
        if (wrongKeyAttempts >= maxWrongKeyAttempts) {
          onStatus?.call(
            'The presented security key does not hold "${entry.label}".',
          );
          throw SSHSecurityKeyNotPresentError(
            '"${entry.label}" is not on the presented security key.',
          );
        }
        onStatus?.call(
          'That security key does not hold "${entry.label}". Present '
          '"${entry.label}" instead.',
        );
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

  Future<_SecurityKeyEntry?> _selectedEntry(_SecurityKeySession session) async {
    if (session.entries.length < 2) {
      return null;
    }
    final existing = session.selectedEntry;
    if (existing != null) {
      return existing;
    }
    final selector = onKeySelect;
    if (selector == null) {
      return null;
    }
    final selection = await selector([
      for (final entry in session.entries) entry.label,
    ]);
    if (selection == null) {
      return null;
    }
    final index = selection.index;
    if (index == null || index < 0 || index >= session.entries.length) {
      onStatus?.call('Security key selection was cancelled.');
      throw StateError('Security key selection was cancelled.');
    }
    final entry = session.entries[index];
    session.selectedEntry = entry;
    onStatus?.call('Using security key "${entry.label}".');
    return entry;
  }

  String _waitingMessage(_SecurityKeySession session) {
    return session.entries.length > 1
        ? 'Waiting for hardware key over USB or NFC. Any of your '
              '${session.entries.length} enrolled keys will work...'
        : 'Waiting for hardware key over USB or NFC...';
  }

  Future<void> _checkPresence(
    CtapDevice device,
    _SecurityKeyEntry entry,
    _SecurityKeySession session,
    List<int> clientDataHash, {
    required bool selectionActive,
  }) async {
    final presence = await _probeCredential(
      device,
      entry.keyPair,
      clientDataHash,
    );
    if (presence == _CredentialPresence.present) {
      session.record(entry, present: true);
      return;
    }
    if (presence == _CredentialPresence.absent) {
      session.record(entry, present: false);
      if (selectionActive) {
        throw const _WrongKeyPresented();
      }
      await _probeSiblings(device, entry, session, clientDataHash);
      throw _mismatchError(entry, session);
    }
  }

  Future<void> _identifyPresentedKey(
    CtapDevice device,
    _SecurityKeyEntry entry,
    _SecurityKeySession session,
    List<int> clientDataHash,
  ) async {
    final presence = await _probeCredential(
      device,
      entry.keyPair,
      clientDataHash,
    );
    if (presence == _CredentialPresence.present) {
      session.record(entry, present: true);
      return;
    }
    await _probeSiblings(device, entry, session, clientDataHash);
    final present = session.presentEntry();
    if (present != null && !identical(present, entry)) {
      throw _mismatchError(entry, session);
    }
  }

  Future<_CredentialPresence> _probeCredential(
    CtapDevice device,
    OpenSSHSecurityKeyPair keyPair,
    List<int> clientDataHash, {
    List<int>? pinAuth,
    int? pinProtocol,
  }) async {
    final request = GetAssertionRequest(
      rpId: keyPair.application,
      clientDataHash: clientDataHash,
      allowList: [
        PublicKeyCredentialDescriptor(
          type: 'public-key',
          id: keyPair.keyHandle,
        ),
      ],
      options: {'up': false},
      pinAuth: pinAuth,
      pinProtocol: pinProtocol,
    );
    final response = await device.transceive(request.encode());
    if (response.status == CtapStatusCode.ctap1ErrSuccess.value) {
      return _CredentialPresence.present;
    }
    if (response.status == CtapStatusCode.ctap2ErrNoCredentials.value) {
      return _CredentialPresence.absent;
    }
    return _CredentialPresence.inconclusive;
  }

  Future<void> _probeSiblings(
    CtapDevice device,
    _SecurityKeyEntry entry,
    _SecurityKeySession session,
    List<int> clientDataHash, {
    List<int>? pinAuth,
    int? pinProtocol,
  }) async {
    for (final sibling in session.entries) {
      if (identical(sibling, entry) || session.hasFreshResult(sibling)) {
        continue;
      }
      final probeWithPin = sibling.requiresUserVerification && pinAuth != null;
      final presence = await _probeCredential(
        device,
        sibling.keyPair,
        clientDataHash,
        pinAuth: probeWithPin ? pinAuth : null,
        pinProtocol: probeWithPin ? pinProtocol : null,
      );
      if (presence == _CredentialPresence.inconclusive) {
        continue;
      }
      final present = presence == _CredentialPresence.present;
      if (present || probeWithPin || !sibling.requiresUserVerification) {
        session.record(sibling, present: present);
      }
    }
  }

  SSHSecurityKeyNotPresentError _mismatchError(
    _SecurityKeyEntry entry,
    _SecurityKeySession session, {
    bool announce = true,
  }) {
    final present = session.presentEntry();
    if (announce) {
      if (present != null) {
        onStatus?.call(
          'This security key holds "${present.label}". Switching to it...',
        );
      } else if (session.allOthersKnownAbsent(entry)) {
        onStatus?.call(
          'This security key does not hold any of the keys saved for '
          'this host.',
        );
      } else {
        onStatus?.call('"${entry.label}" is not on this security key.');
      }
    }
    return SSHSecurityKeyNotPresentError(
      '"${entry.label}" is not on the presented security key.',
      preferredPublicKey: present?.keyPair.toPublicKey().encode(),
    );
  }

  Future<GetAssertionRequest> _buildAssertionRequest({
    required CtapDevice device,
    required _SecurityKeySession session,
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
            session: session,
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
    required _SecurityKeySession session,
    required List<int> clientDataHash,
    required String rpId,
    String? presetPin,
  }) async {
    final ctap = await Ctap2.create(device);
    final pinProtocol = _pinProtocolFor(ctap.info);
    final clientPin = ClientPin(ctap, pinProtocol: pinProtocol);

    Future<_PinAuth> authWithPin(String pin) async {
      final token = await clientPin.getPinToken(
        pin,
        permissions: [ClientPinPermission.getAssertion],
        permissionsRpId: rpId,
      );
      session.recordPin(pin);
      onStatus?.call('Security key PIN accepted.');
      final auth = await pinProtocol.authenticate(token, clientDataHash);
      return _PinAuth(authParam: auth, protocolVersion: pinProtocol.version);
    }

    if (presetPin != null) {
      try {
        return await authWithPin(presetPin);
      } on CtapError catch (error) {
        if (error.status == CtapStatusCode.ctap2ErrPinInvalid) {
          session.clearPin();
          throw _PinRejected(error, await _pinRetries(clientPin));
        }
        rethrow;
      }
    }

    final cachedPin = session.cachedPin;
    if (cachedPin != null) {
      try {
        return await authWithPin(cachedPin);
      } on CtapError catch (error) {
        if (error.status != CtapStatusCode.ctap2ErrPinInvalid) {
          rethrow;
        }
        session.clearPin();
        onStatus?.call('Enter the PIN for this security key.');
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
        return await authWithPin(pin);
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

enum _CredentialPresence { present, absent, inconclusive }

class _SecurityKeyEntry {
  _SecurityKeyEntry({required this.keyPair, required this.label});

  final OpenSSHSecurityKeyPair keyPair;
  final String label;

  String get credentialId => base64.encode(keyPair.keyHandle);

  bool get requiresUserVerification => keyPair.flags & 0x04 != 0;
}

/// Probe results describe the physical key presented moments ago, so they
/// expire quickly: skipping stale entries could reject a key the user has
/// since swapped in, and agent-forwarded signatures may arrive much later.
class _SecurityKeySession {
  static const _presenceTtl = Duration(seconds: 20);
  static const _pinTtl = Duration(minutes: 2);

  final entries = <_SecurityKeyEntry>[];
  _SecurityKeyEntry? selectedEntry;
  final _presence = <String, bool>{};
  DateTime? _recordedAt;
  String? _pin;
  DateTime? _pinRecordedAt;

  String? get cachedPin {
    final recordedAt = _pinRecordedAt;
    if (_pin == null ||
        recordedAt == null ||
        DateTime.now().difference(recordedAt) >= _pinTtl) {
      return null;
    }
    return _pin;
  }

  void recordPin(String pin) {
    _pin = pin;
    _pinRecordedAt = DateTime.now();
  }

  void clearPin() {
    _pin = null;
    _pinRecordedAt = null;
  }

  bool get _fresh =>
      _recordedAt != null &&
      DateTime.now().difference(_recordedAt!) < _presenceTtl;

  void record(_SecurityKeyEntry entry, {required bool present}) {
    if (!_fresh) {
      _presence.clear();
    }
    _presence[entry.credentialId] = present;
    _recordedAt = DateTime.now();
  }

  bool hasFreshResult(_SecurityKeyEntry entry) =>
      _fresh && _presence.containsKey(entry.credentialId);

  bool isKnownAbsent(_SecurityKeyEntry entry) =>
      _fresh && _presence[entry.credentialId] == false;

  _SecurityKeyEntry? presentEntry() {
    if (!_fresh) {
      return null;
    }
    for (final entry in entries) {
      if (_presence[entry.credentialId] == true) {
        return entry;
      }
    }
    return null;
  }

  bool allOthersKnownAbsent(_SecurityKeyEntry entry) {
    if (!_fresh) {
      return false;
    }
    return entries.every(
      (other) =>
          identical(other, entry) || _presence[other.credentialId] == false,
    );
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

class _WrongKeyPresented implements Exception {
  const _WrongKeyPresented();
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

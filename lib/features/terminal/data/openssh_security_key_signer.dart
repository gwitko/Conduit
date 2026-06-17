import 'package:crypto/crypto.dart' as crypto;
import 'package:dartssh2/dartssh2.dart';
import 'package:fido2/fido2_client.dart';
import 'package:flutter/services.dart';

import 'fido_nfc_ctap_device.dart';
import 'fido_usb_ctap_device.dart';

typedef CtapDeviceOpener = Future<CtapDevice> Function();
typedef CtapDeviceCloser = Future<void> Function(CtapDevice device, bool ok);
typedef SecurityKeyStatusHandler = void Function(String message);

class OpenSshSecurityKeySigner {
  const OpenSshSecurityKeySigner({
    required this.openDevice,
    this.closeDevice,
    this.onStatus,
  });

  final CtapDeviceOpener openDevice;
  final CtapDeviceCloser? closeDevice;
  final SecurityKeyStatusHandler? onStatus;

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
    final request = GetAssertionRequest(
      rpId: keyPair.application,
      clientDataHash: crypto.sha256.convert(data).bytes,
      allowList: [
        PublicKeyCredentialDescriptor(
          type: 'public-key',
          id: keyPair.keyHandle,
        ),
      ],
      options: {
        'up': true,
        if (_requiresUserVerification(keyPair.flags)) 'uv': true,
      },
    );

    for (var attempt = 0; attempt < 2; attempt++) {
      onStatus?.call('Waiting for hardware key over USB or NFC...');
      final device = await openDevice();
      var ok = false;
      try {
        onStatus?.call(_interactionMessage(device));
        final response = await device.transceive(request.encode());
        if (response.status != CtapStatusCode.ctap1ErrSuccess.value) {
          throw CtapError.fromCode(response.status);
        }
        ok = true;
        onStatus?.call('Hardware key accepted.');
        return GetAssertionResponse.decode(response.data);
      } catch (error) {
        if (attempt == 0 && _shouldRetryNfc(device, error)) {
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

    throw StateError('Security key signing did not complete.');
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

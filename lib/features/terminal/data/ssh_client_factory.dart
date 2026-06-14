import 'dart:async';

import 'package:conduit/core/app_failure.dart';
import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:conduit/features/terminal/data/fido_hardware_key_ctap_device.dart';
import 'package:conduit/features/terminal/data/openssh_security_key_signer.dart';
import 'package:conduit/features/terminal/domain/host_key_verifier.dart';
import 'package:conduit/features/terminal/domain/security_key_interaction.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart' show Uint8List, visibleForTesting;

typedef SshKeyPairParser =
    List<SSHKeyPair> Function(String pemText, String? passphrase);

class SshClientFactory {
  SshClientFactory(
    this._hostKeyVerifier, {
    OpenSshSecurityKeySigner? securityKeySigner,
    SshKeyPairParser? keyPairParser,
  }) : _securityKeySigner =
           securityKeySigner ??
           OpenSshSecurityKeySigner(
             openDevice: FidoHardwareKeyCtapDevice.open,
             closeDevice: FidoHardwareKeyCtapDevice.close,
             onStatus: SecurityKeyInteraction.instance.announce,
           ),
       _keyPairParser = keyPairParser ?? SSHKeyPair.fromPem;

  final HostKeyVerifier _hostKeyVerifier;
  final OpenSshSecurityKeySigner _securityKeySigner;
  final SshKeyPairParser _keyPairParser;

  Future<SSHClient> connect(SavedHost host) async {
    SSHSocket? socket;
    try {
      socket = await SSHSocket.connect(
        host.host.trim(),
        host.port,
        timeout: Duration(seconds: host.connectionTimeoutSeconds),
      );
      return SSHClient(
        socket,
        username: host.username.trim(),
        identities: _identitiesFor(host),
        onPasswordRequest: _passwordRequestFor(host),
        onUserInfoRequest: _userInfoRequestFor(host),
        onVerifyHostKey: (type, fingerprint) {
          return _hostKeyVerifier.verify(
            host: host.host.trim(),
            port: host.port,
            type: type,
            fingerprint: _formatFingerprint(fingerprint),
          );
        },
      );
    } catch (_) {
      unawaited(socket?.close() ?? Future<void>.value());
      rethrow;
    }
  }

  List<SSHKeyPair>? _identitiesFor(SavedHost host) {
    if (host.authMethod != SshAuthMethod.privateKey &&
        host.authMethod != SshAuthMethod.hardwareKey) {
      return null;
    }
    try {
      final keyPairs = _keyPairParser(
        host.privateKey,
        host.passphrase.isEmpty ? null : host.passphrase,
      );
      if (host.authMethod == SshAuthMethod.privateKey &&
          keyPairs.any((keyPair) => keyPair is OpenSSHSecurityKeyPair)) {
        throw const AppFailure(
          'This is a hardware-key stub. Choose Hardware key instead.',
        );
      }
      if (host.authMethod == SshAuthMethod.hardwareKey) {
        final securityKeyPairs = keyPairs
            .whereType<OpenSSHSecurityKeyPair>()
            .toList(growable: false);
        if (securityKeyPairs.isEmpty) {
          throw const AppFailure(
            'Hardware key auth requires an OpenSSH security-key stub '
            '(id_ed25519_sk or id_ecdsa_sk), not a normal private key.',
          );
        }
        return _securityKeySigner.attach(securityKeyPairs);
      }
      return _securityKeySigner.attach(keyPairs);
    } catch (error) {
      if (error is AppFailure) {
        rethrow;
      }
      throw AppFailure('Private key could not be loaded.', error);
    }
  }

  @visibleForTesting
  List<SSHKeyPair>? identitiesForTesting(SavedHost host) =>
      _identitiesFor(host);

  String Function()? _passwordRequestFor(SavedHost host) {
    return host.authMethod == SshAuthMethod.password
        ? () => host.password
        : null;
  }

  SSHUserInfoRequestHandler? _userInfoRequestFor(SavedHost host) {
    if (host.authMethod != SshAuthMethod.password) {
      return null;
    }
    return (request) {
      var answered = false;
      return [
        for (final prompt in request.prompts)
          if (!prompt.echo && !answered)
            (() {
              answered = true;
              return host.password;
            })()
          else
            '',
      ];
    };
  }

  String _formatFingerprint(Uint8List bytes) {
    final parts = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0'));
    return 'MD5:${parts.join(':')}';
  }
}

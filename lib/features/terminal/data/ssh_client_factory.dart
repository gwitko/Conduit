import 'dart:async';
import 'dart:convert';

import 'package:conduit/core/app_failure.dart';
import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:conduit/features/terminal/data/bastion_ssh_socket.dart';
import 'package:conduit/features/terminal/data/fido_hardware_key_ctap_device.dart';
import 'package:conduit/features/terminal/data/openssh_security_key_signer.dart';
import 'package:conduit/features/terminal/data/tcp_ssh_socket.dart';
import 'package:conduit/features/terminal/domain/host_key_verifier.dart';
import 'package:conduit/features/terminal/domain/security_key_interaction.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart' show Uint8List, visibleForTesting;
import 'package:pinenacl/ed25519.dart' as ed25519;

typedef SshKeyPairParser =
    List<SSHKeyPair> Function(String pemText, String? passphrase);

/// Looks up a saved machine by id so it can be used as a bastion.
typedef BastionHostResolver = SavedHost? Function(String id);

class SshClientFactory {
  SshClientFactory(
    this._hostKeyVerifier, {
    this.resolveBastionHost,
    OpenSshSecurityKeySigner? securityKeySigner,
    SshKeyPairParser? keyPairParser,
  }) : _securityKeySigner =
           securityKeySigner ??
           OpenSshSecurityKeySigner(
             openDevice: FidoHardwareKeyCtapDevice.open,
             closeDevice: FidoHardwareKeyCtapDevice.close,
             onStatus: SecurityKeyInteraction.instance.announce,
             onPinRequest: SecurityKeyInteraction.instance.requestPin,
             onKeySelect: SecurityKeyInteraction.instance.requestKeySelection,
           ),
       _keyPairParser = keyPairParser ?? SSHKeyPair.fromPem;

  final HostKeyVerifier _hostKeyVerifier;
  final BastionHostResolver? resolveBastionHost;
  final OpenSshSecurityKeySigner _securityKeySigner;
  final SshKeyPairParser _keyPairParser;
  SSHKeyPair? _externalAuthIdentity;

  Future<SSHClient> connect(SavedHost host) async {
    SSHSocket? socket;
    try {
      socket = await _socketFor(host);
      final identities = _identitiesFor(host);
      return SSHClient(
        socket,
        username: host.username.trim(),
        identities: identities,
        agentHandler: _agentHandlerFor(host, identities),
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

  Future<SSHSocket> _socketFor(SavedHost host) async {
    final referencedBastion = _referencedBastionProfile(host);
    if (referencedBastion != null) {
      return _socketThroughBastion(host, referencedBastion);
    }
    final bastion = host.bastion;
    if (bastion == null || !bastion.isConfigured) {
      return TcpSshSocket.connect(
        host.host.trim(),
        host.port,
        timeout: Duration(seconds: host.connectionTimeoutSeconds),
      );
    }
    return _socketThroughBastion(
      host,
      bastion.toSavedHost(
        connectionTimeoutSeconds: host.connectionTimeoutSeconds,
      ),
    );
  }

  /// Resolves [SavedHost.bastionHostId] to a direct connection profile.
  ///
  /// The returned host has its own bastion cleared so hopping stays single
  /// level, and its Mosh/tmux settings are ignored because only its SSH
  /// transport is used.
  SavedHost? _referencedBastionProfile(SavedHost host) {
    final id = host.bastionHostId.trim();
    if (id.isEmpty) {
      return null;
    }
    final resolver = resolveBastionHost;
    final resolved = resolver?.call(id);
    if (resolved == null) {
      throw const AppFailure(
        'The bastion machine for this host is no longer available.',
      );
    }
    if (resolved.id == host.id) {
      throw const AppFailure('A machine cannot use itself as its own bastion.');
    }
    if (resolved.isLocal) {
      throw const AppFailure('A local shell cannot be used as an SSH bastion.');
    }
    return resolved.copyWith(bastionHostId: '', clearBastion: true);
  }

  @visibleForTesting
  SavedHost? referencedBastionProfileForTesting(SavedHost host) =>
      _referencedBastionProfile(host);

  Future<SSHSocket> _socketThroughBastion(
    SavedHost host,
    SavedHost bastion,
  ) async {
    SSHClient? bastionClient;
    try {
      bastionClient = await connect(bastion);
      final tunnel = await bastionClient.forwardLocal(
        host.host.trim(),
        host.port,
      );
      final client = bastionClient;
      bastionClient = null;
      return BastionSshSocket(tunnel: tunnel, closeBastion: client.close);
    } catch (error) {
      bastionClient?.close();
      if (error is AppFailure) {
        rethrow;
      }
      throw AppFailure(
        'Could not reach ${host.host.trim()}:${host.port} through the bastion '
        '${bastion.endpoint}.',
        error,
      );
    }
  }

  List<SSHKeyPair>? _identitiesFor(SavedHost host) {
    if (host.authMethod == SshAuthMethod.external &&
        host.externalAuthOfferKey) {
      return [_externalAuthIdentity ??= _generateExternalAuthIdentity()];
    }
    if (host.authMethod == SshAuthMethod.hardwareKey) {
      return _hardwareKeyIdentitiesFor(host);
    }
    if (host.authMethod != SshAuthMethod.privateKey) {
      return null;
    }
    try {
      final keyPairs = _keyPairParser(
        host.privateKey,
        host.passphrase.isEmpty ? null : host.passphrase,
      );
      if (keyPairs.any((keyPair) => keyPair is OpenSSHSecurityKeyPair)) {
        throw const AppFailure(
          'This is a hardware-key stub. Choose Hardware key instead.',
        );
      }
      return _securityKeySigner.attach(keyPairs);
    } catch (error) {
      if (error is AppFailure) {
        rethrow;
      }
      throw AppFailure('Private key could not be loaded.', error);
    }
  }

  List<SSHKeyPair> _hardwareKeyIdentitiesFor(SavedHost host) {
    final entries = host.effectiveHardwareKeys;
    if (entries.isEmpty) {
      throw const AppFailure('Add at least one hardware key to this host.');
    }
    final keyPairs = <SSHKeyPair>[];
    final labels = <String>[];
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final label = entry.label.trim().isEmpty
          ? 'hardware key ${i + 1}'
          : entry.label.trim();
      final List<SSHKeyPair> parsed;
      try {
        parsed = _keyPairParser(
          entry.privateKey,
          entry.passphrase.isEmpty ? null : entry.passphrase,
        );
      } catch (error) {
        throw AppFailure('Hardware key "$label" could not be loaded.', error);
      }
      final securityKeyPairs = parsed
          .whereType<OpenSSHSecurityKeyPair>()
          .toList(growable: false);
      if (securityKeyPairs.isEmpty) {
        throw AppFailure(
          'Hardware key "$label" requires an OpenSSH security-key stub '
          '(id_ed25519_sk or id_ecdsa_sk), not a normal private key.',
        );
      }
      for (final keyPair in securityKeyPairs) {
        keyPairs.add(keyPair);
        labels.add(label);
      }
    }
    return _securityKeySigner.attach(keyPairs, labels: labels);
  }

  @visibleForTesting
  List<SSHKeyPair>? identitiesForTesting(SavedHost host) =>
      _identitiesFor(host);

  SSHAgentHandler? _agentHandlerFor(
    SavedHost host,
    List<SSHKeyPair>? identities,
  ) {
    if (host.authMethod == SshAuthMethod.external ||
        !host.forwardAgent ||
        identities == null ||
        identities.isEmpty) {
      return null;
    }
    return SSHKeyPairAgent(identities);
  }

  @visibleForTesting
  SSHAgentHandler? agentHandlerForTesting(SavedHost host) =>
      _agentHandlerFor(host, _identitiesFor(host));

  @visibleForTesting
  String formatFingerprintForTesting(Uint8List bytes) =>
      _formatFingerprint(bytes);

  @visibleForTesting
  String Function()? passwordRequestForTesting(SavedHost host) =>
      _passwordRequestFor(host);

  @visibleForTesting
  SSHUserInfoRequestHandler? userInfoRequestForTesting(SavedHost host) =>
      _userInfoRequestFor(host);

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

  SSHKeyPair _generateExternalAuthIdentity() {
    final signingKey = ed25519.SigningKey.generate();
    return OpenSSHEd25519KeyPair(
      Uint8List.fromList(signingKey.verifyKey.asTypedList),
      Uint8List.fromList(signingKey.asTypedList),
      'conduit-external-auth',
    );
  }

  String _formatFingerprint(Uint8List bytes) {
    final text = utf8.decode(bytes, allowMalformed: true);
    if (text.startsWith('SHA256:')) {
      return text;
    }
    final parts = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0'));
    return 'MD5:${parts.join(':')}';
  }
}

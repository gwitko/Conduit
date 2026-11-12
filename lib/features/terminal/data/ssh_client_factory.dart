import 'dart:async';
import 'dart:convert';

import 'package:conduit/core/app_failure.dart';
import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:conduit/features/terminal/data/fido_hardware_key_ctap_device.dart';
import 'package:conduit/features/terminal/data/openssh_security_key_signer.dart';
import 'package:conduit/features/terminal/data/tcp_ssh_socket.dart';
import 'package:conduit/features/terminal/domain/host_key_verifier.dart';
import 'package:conduit/features/terminal/domain/security_key_interaction.dart';
import 'package:conduit/features/terminal/domain/ssh_password_interaction.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart' show Uint8List, visibleForTesting;
import 'package:pinenacl/ed25519.dart' as ed25519;

typedef SshKeyPairParser =
    List<SSHKeyPair> Function(String pemText, String? passphrase);

class SshClientFactory {
  SshClientFactory(
    this._hostKeyVerifier, {
    OpenSshSecurityKeySigner? securityKeySigner,
    SshKeyPairParser? keyPairParser,
    SshPasswordPrompt? passwordPrompt,
  }) : _passwordPrompt =
           passwordPrompt ?? SshPasswordInteraction.instance.requestPassword,
       _securityKeySigner =
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
  final OpenSshSecurityKeySigner _securityKeySigner;
  final SshKeyPairParser _keyPairParser;
  final SshPasswordPrompt _passwordPrompt;
  SSHKeyPair? _externalAuthIdentity;

  Future<SSHClient> connect(SavedHost host) async {
    SSHSocket? socket;
    try {
      socket = await TcpSshSocket.connect(
        host.host.trim(),
        host.port,
        timeout: Duration(seconds: host.connectionTimeoutSeconds),
      );
      final identities = _identitiesFor(host);
      final promptState = _PasswordPromptState();
      return SSHClient(
        socket,
        username: host.username.trim(),
        identities: identities,
        agentHandler: _agentHandlerFor(host, identities),
        onPasswordRequest: _passwordRequestFor(host, promptState),
        onUserInfoRequest: _userInfoRequestFor(host, promptState),
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
  SSHPasswordRequestHandler? passwordRequestForTesting(SavedHost host) =>
      _passwordRequestFor(host);

  @visibleForTesting
  SSHUserInfoRequestHandler? userInfoRequestForTesting(SavedHost host) =>
      _userInfoRequestFor(host);

  /// Both handlers of one connection, sharing its prompt-cancel state.
  @visibleForTesting
  ({
    SSHPasswordRequestHandler? password,
    SSHUserInfoRequestHandler? userInfo,
  })
  authHandlersForTesting(SavedHost host) {
    final state = _PasswordPromptState();
    return (
      password: _passwordRequestFor(host, state),
      userInfo: _userInfoRequestFor(host, state),
    );
  }

  /// Key-based hosts can still be asked for a password: OpenSSH servers with
  /// `AuthenticationMethods publickey,password` (or `…,keyboard-interactive`)
  /// accept the key with partial success and then require a second method.
  /// dartssh2 only continues if these handlers exist, so key hosts get them
  /// too. A password saved on the host is used as-is; otherwise the user is
  /// prompted, like OpenSSH does.
  static bool _mayAskForPassword(SavedHost host) =>
      host.authMethod == SshAuthMethod.privateKey ||
      host.authMethod == SshAuthMethod.hardwareKey;

  SSHPasswordRequestHandler? _passwordRequestFor(
    SavedHost host, [
    _PasswordPromptState? state,
  ]) {
    if (host.authMethod == SshAuthMethod.password) {
      return () => host.password;
    }
    if (!_mayAskForPassword(host)) {
      return null;
    }
    final promptState = state ?? _PasswordPromptState();
    return () {
      if (host.password.isNotEmpty) {
        return host.password;
      }
      return _prompt(
        promptState,
        SshPasswordPromptRequest(
          username: host.username.trim(),
          host: host.host.trim(),
        ),
      );
    };
  }

  SSHUserInfoRequestHandler? _userInfoRequestFor(
    SavedHost host, [
    _PasswordPromptState? state,
  ]) {
    if (host.authMethod == SshAuthMethod.password ||
        (_mayAskForPassword(host) && host.password.isNotEmpty)) {
      return (request) => _answerWithPassword(
        request.prompts.map((prompt) => prompt.echo),
        host.password,
      );
    }
    if (!_mayAskForPassword(host)) {
      return null;
    }
    final promptState = state ?? _PasswordPromptState();
    return (request) async {
      final answers = <String>[];
      for (final prompt in request.prompts) {
        final answer = await _prompt(
          promptState,
          SshPasswordPromptRequest(
            username: host.username.trim(),
            host: host.host.trim(),
            prompt: prompt.promptText,
            instruction: request.instruction,
            echo: prompt.echo,
          ),
        );
        if (answer == null) {
          return null;
        }
        answers.add(answer);
      }
      return answers;
    };
  }

  /// Once the user cancels a prompt, later methods of the same connection
  /// (password, then keyboard-interactive) fail silently instead of asking
  /// again.
  Future<String?> _prompt(
    _PasswordPromptState state,
    SshPasswordPromptRequest request,
  ) async {
    if (state.cancelled) {
      return null;
    }
    final answer = await _passwordPrompt(request);
    if (answer == null) {
      state.cancelled = true;
    }
    return answer;
  }

  static List<String> _answerWithPassword(
    Iterable<bool> echoes,
    String password,
  ) {
    var answered = false;
    return [
      for (final echo in echoes)
        if (!echo && !answered)
          (() {
            answered = true;
            return password;
          })()
        else
          '',
    ];
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

class _PasswordPromptState {
  bool cancelled = false;
}

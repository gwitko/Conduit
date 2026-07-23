import 'dart:async';
import 'dart:convert';

import 'package:conduit/core/app_failure.dart';
import 'package:conduit/features/agent_attention/domain/agent_command_runner.dart';
import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:conduit/features/terminal/data/ssh_client_factory.dart';
import 'package:conduit/features/terminal/data/ssh_error_formatter.dart';
import 'package:conduit/features/terminal/domain/host_key_verifier.dart';
import 'package:dartssh2/dartssh2.dart';

/// Runs agent-provider commands over a dedicated SSH exec channel.
///
/// Uses the same authentication stack as the terminal and SFTP (via
/// [SshClientFactory]) but its own connection, opened lazily on first use
/// and kept for subsequent polls; a broken connection is dropped so the
/// next call reconnects. Never touches the interactive PTY.
class SshAgentCommandRunner implements AgentCommandRunner {
  SshAgentCommandRunner(this._hostKeyVerifier, this._host);

  final HostKeyVerifier _hostKeyVerifier;
  final SavedHost _host;

  Future<SSHClient>? _client;
  bool _closed = false;

  @override
  Future<AgentCommandResult> run(
    String command, {
    required Duration timeout,
  }) async {
    if (_closed) {
      throw const AppFailure('This connection is closed.');
    }
    final SSHClient client;
    try {
      client = await (_client ??= SshClientFactory(
        _hostKeyVerifier,
      ).connect(_host));
    } catch (error) {
      _client = null;
      throw AppFailure(
        'Could not reach ${_host.name}.',
        describeSshConnectionError(error),
      );
    }
    try {
      final result = await client.runWithResult(command).timeout(timeout);
      return AgentCommandResult(
        stdout: utf8.decode(result.stdout, allowMalformed: true),
        stderr: utf8.decode(result.stderr, allowMalformed: true),
        exitCode: result.exitCode,
      );
    } on TimeoutException {
      // A hung exec channel usually means the connection is going away;
      // drop it so the next poll starts fresh.
      await _dropClient();
      throw const AppFailure('The command timed out.');
    } catch (error) {
      await _dropClient();
      throw AppFailure(
        'Running a command on ${_host.name} failed.',
        describeSshConnectionError(error),
      );
    }
  }

  Future<void> _dropClient() async {
    final pending = _client;
    _client = null;
    if (pending != null) {
      try {
        (await pending).close();
      } catch (_) {
        // The connection is already gone.
      }
    }
  }

  @override
  Future<void> close() async {
    _closed = true;
    await _dropClient();
  }
}

import 'dart:typed_data';

import 'package:conduit/core/app_failure.dart';
import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:conduit/features/terminal/data/ssh_client_factory.dart';
import 'package:conduit/features/terminal/data/ssh_error_formatter.dart';
import 'package:conduit/features/terminal/domain/host_key_verifier.dart';
import 'package:conduit/features/terminal/domain/ssh_terminal_repository.dart';
import 'package:conduit/features/terminal/domain/ssh_terminal_session.dart';
import 'package:dartssh2/dartssh2.dart';

class DartSshTerminalRepository implements SshTerminalRepository {
  const DartSshTerminalRepository(
    this._hostKeyVerifier, {
    this.resolveBastionHost,
  });

  final HostKeyVerifier _hostKeyVerifier;
  final BastionHostResolver? resolveBastionHost;
  SshClientFactory get _clientFactory => SshClientFactory(
    _hostKeyVerifier,
    resolveBastionHost: resolveBastionHost,
  );

  HostKeyVerifier get hostKeyVerifier => _hostKeyVerifier;

  @override
  Future<SshTerminalSession> connect(
    SavedHost host, {
    required int columns,
    required int rows,
  }) async {
    SSHClient? client;
    try {
      client = await _clientFactory.connect(host);

      final shell = await client.shell(
        pty: SSHPtyConfig(width: columns, height: rows),
      );

      return DartSshTerminalSession(client: client, shell: shell);
    } catch (error) {
      client?.close();
      throw AppFailure(
        'Could not connect to ${host.host}:${host.port}.',
        describeSshConnectionError(error),
      );
    }
  }
}

class DartSshTerminalSession implements SshTerminalSession {
  DartSshTerminalSession({required this.client, required this.shell});

  final SSHClient client;
  final SSHSession shell;
  bool _closed = false;

  @override
  Stream<List<int>> get stdout => shell.stdout;

  @override
  Stream<List<int>> get stderr => shell.stderr;

  @override
  Future<void> get done => shell.done;

  @override
  Future<void> send(List<int> data) async {
    if (_closed) {
      throw const AppFailure('The SSH session is closed.');
    }

    shell.write(Uint8List.fromList(data));
  }

  @override
  void resize(int columns, int rows, int pixelWidth, int pixelHeight) {
    if (_closed) {
      return;
    }

    shell.resizeTerminal(columns, rows, pixelWidth, pixelHeight);
  }

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }

    _closed = true;
    shell.close();
    client.close();
    await client.done;
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:conduit/core/app_failure.dart';
import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:conduit/features/terminal/data/ssh_client_factory.dart';
import 'package:conduit/features/terminal/data/tcp_ssh_socket.dart';
import 'package:conduit/features/terminal/domain/host_key_verifier.dart';
import 'package:conduit/features/terminal/domain/predictive_terminal_session.dart';
import 'package:conduit/features/terminal/domain/roaming_terminal_session.dart';
import 'package:conduit/features/terminal/domain/ssh_terminal_repository.dart';
import 'package:conduit/features/terminal/domain/ssh_terminal_session.dart';
import 'package:dart_mosh/dart_mosh.dart';
import 'package:dartssh2/dartssh2.dart';

class MoshTerminalRepository implements SshTerminalRepository {
  const MoshTerminalRepository(this._hostKeyVerifier);

  final HostKeyVerifier _hostKeyVerifier;

  SshClientFactory get _clientFactory => SshClientFactory(_hostKeyVerifier);

  @override
  Future<SshTerminalSession> connect(
    SavedHost host, {
    required int columns,
    required int rows,
  }) async {
    SSHClient? client;
    try {
      client = await _clientFactory.connect(host);
      final server = await _bootstrap(client, host);
      final socket = client.socket;
      final address = socket is TcpSshSocket ? socket.remoteAddress : null;
      client.close();
      client = null;

      final session = await MoshSession.connect(
        server: server,
        cipher: MoshPacketCipher.aesOcb(server.key),
        address: address,
        columns: columns,
        rows: rows,
      );
      return MoshTerminalSession(session);
    } catch (error) {
      client?.close();
      throw AppFailure(
        'Could not start a Mosh session on ${host.host}:${host.port}.',
        error,
      );
    }
  }

  Future<MoshServerConfig> _bootstrap(SSHClient client, SavedHost host) async {
    final ports = MoshPortRange.tryParse(host.moshPorts);
    final bootstrap = ports == null
        ? MoshSshBootstrap(locale: host.moshLocale)
        : MoshSshBootstrap(
            locale: host.moshLocale,
            serverPort: ports.first,
            serverPortEnd: ports.last,
          );
    final session = await client.execute(bootstrap.command());
    final output = StringBuffer();

    Future<void> drain(Stream<List<int>> stream) => stream.forEach(
      (chunk) => output.write(utf8.decode(chunk, allowMalformed: true)),
    );

    try {
      await Future.wait([
        drain(session.stdout),
        drain(session.stderr),
      ]).timeout(Duration(seconds: host.connectionTimeoutSeconds));
    } on TimeoutException {
      session.close();
      throw const AppFailure('Timed out waiting for mosh-server startup.');
    }

    return MoshServerConfig.parse(output.toString(), host: host.host.trim());
  }
}

class MoshTerminalSession
    implements
        SshTerminalSession,
        RoamingTerminalSession,
        PredictiveTerminalSession {
  MoshTerminalSession(this._session) {
    _errorSubscription = _session.errors.listen((error) {
      if (!_closed) {
        _stderr.add(utf8.encode('$error\r\n'));
      }
    });
  }

  final MoshSession _session;
  final _stderr = StreamController<List<int>>.broadcast();
  StreamSubscription<Object>? _errorSubscription;
  bool _closed = false;

  @override
  Stream<List<int>> get stdout => _session.stdout;

  @override
  Stream<List<int>> get stderr => _stderr.stream;

  @override
  Future<void> get done => _session.done;

  @override
  Stream<int> get echoAcks => _session.echoAcks;

  @override
  Duration? get smoothedRtt => _session.smoothedRtt;

  @override
  Future<void> send(List<int> data) async {
    sendWithInputState(data);
  }

  @override
  int sendWithInputState(List<int> data) {
    if (_closed) {
      throw const AppFailure('The Mosh session is closed.');
    }
    return _session.send(data);
  }

  @override
  void resize(int columns, int rows, int pixelWidth, int pixelHeight) {
    if (_closed) {
      return;
    }
    _session.resize(columns, rows);
  }

  @override
  Future<void> rehome() async {
    if (_closed) {
      return;
    }
    await _session.rehome();
  }

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    await _errorSubscription?.cancel();
    await _session.close();
    await _stderr.close();
  }
}

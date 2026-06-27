import 'dart:typed_data';

import 'package:conduit/core/app_failure.dart';
import 'package:conduit/features/local_shell/domain/pty_process.dart';
import 'package:conduit/features/terminal/domain/ssh_terminal_session.dart';

class LocalTerminalSession implements SshTerminalSession {
  LocalTerminalSession(this._process);

  final PtyProcess _process;
  bool _closed = false;

  @override
  Stream<List<int>> get stdout => _process.output;

  @override
  Stream<List<int>> get stderr => const Stream<List<int>>.empty();

  @override
  Future<void> get done => _process.exitCode.then((_) {});

  @override
  Future<void> send(List<int> data) async {
    if (_closed) {
      throw const AppFailure('The local shell session is closed.');
    }
    _process.write(data is Uint8List ? data : Uint8List.fromList(data));
  }

  @override
  void resize(int columns, int rows, int pixelWidth, int pixelHeight) {
    if (_closed) return;
    _process.resize(rows, columns);
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _process.kill();
    await _process.exitCode.then<void>((_) {}).catchError((_) {});
  }
}

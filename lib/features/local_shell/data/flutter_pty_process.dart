import 'dart:io';
import 'dart:typed_data';

import 'package:conduit/features/local_shell/domain/pty_process.dart';
import 'package:flutter_pty/flutter_pty.dart';

class FlutterPtyProcess implements PtyProcess {
  FlutterPtyProcess(this._pty);

  factory FlutterPtyProcess.start({
    required String executable,
    required List<String> arguments,
    required Map<String, String> environment,
    int rows = 25,
    int columns = 80,
    String? workingDirectory,
  }) {
    final pty = Pty.start(
      executable,
      arguments: arguments,
      environment: environment,
      workingDirectory: workingDirectory,
      rows: rows,
      columns: columns,
    );
    return FlutterPtyProcess(pty);
  }

  final Pty _pty;

  @override
  Stream<Uint8List> get output => _pty.output;

  @override
  Future<int> get exitCode => _pty.exitCode;

  @override
  void write(Uint8List data) => _pty.write(data);

  @override
  void resize(int rows, int columns) => _pty.resize(rows, columns);

  @override
  void kill() {
    try {
      _pty.kill(ProcessSignal.sigkill);
    } catch (_) {}
  }
}

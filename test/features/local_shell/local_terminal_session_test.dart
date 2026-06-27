import 'dart:async';
import 'dart:typed_data';

import 'package:conduit/core/app_failure.dart';
import 'package:conduit/features/local_shell/data/local_terminal_session.dart';
import 'package:conduit/features/local_shell/domain/pty_process.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePtyProcess implements PtyProcess {
  final _output = StreamController<Uint8List>.broadcast();
  final _exit = Completer<int>();
  final writes = <List<int>>[];
  final resizes = <List<int>>[];
  bool killed = false;

  void emit(List<int> data) => _output.add(Uint8List.fromList(data));
  void complete(int code) {
    if (!_exit.isCompleted) _exit.complete(code);
  }

  @override
  Stream<Uint8List> get output => _output.stream;

  @override
  Future<int> get exitCode => _exit.future;

  @override
  void write(Uint8List data) => writes.add(data);

  @override
  void resize(int rows, int columns) => resizes.add([rows, columns]);

  @override
  void kill() {
    killed = true;
    complete(-9);
  }
}

void main() {
  group('LocalTerminalSession', () {
    test('forwards pty output as stdout', () async {
      final pty = FakePtyProcess();
      final session = LocalTerminalSession(pty);
      final received = <int>[];
      final sub = session.stdout.listen(received.addAll);

      pty.emit([104, 105]);
      await Future<void>.delayed(Duration.zero);
      expect(received, [104, 105]);
      await sub.cancel();
    });

    test('stderr is empty (pty merges streams)', () async {
      final session = LocalTerminalSession(FakePtyProcess());
      expect(await session.stderr.toList(), isEmpty);
    });

    test('send writes bytes to the pty', () async {
      final pty = FakePtyProcess();
      final session = LocalTerminalSession(pty);
      await session.send([1, 2, 3]);
      expect(pty.writes.single, [1, 2, 3]);
    });

    test('resize swaps to (rows, columns) ordering for the ioctl', () {
      final pty = FakePtyProcess();
      LocalTerminalSession(pty).resize(80, 24, 0, 0);
      expect(pty.resizes.single, [24, 80]);
    });

    test('close kills the process and completes done', () async {
      final pty = FakePtyProcess();
      final session = LocalTerminalSession(pty);
      await session.close();
      expect(pty.killed, isTrue);
      await session.done; // completes without hanging
    });

    test('send after close throws', () async {
      final pty = FakePtyProcess();
      final session = LocalTerminalSession(pty);
      await session.close();
      expect(() => session.send([1]), throwsA(isA<AppFailure>()));
    });
  });
}

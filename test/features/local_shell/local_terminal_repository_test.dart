import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:conduit/features/local_shell/data/local_terminal_repository.dart';
import 'package:conduit/features/local_shell/domain/local_shell_paths.dart';
import 'package:conduit/features/local_shell/domain/pty_process.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('LocalTerminalRepository', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'conduit_local_terminal_repository_test_',
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('binds shared Android storage into the local shell', () async {
      late List<String> capturedArguments;
      final paths = LocalShellPaths(
        nativeLibraryDir: p.join(tempDir.path, 'lib'),
        dataDir: p.join(tempDir.path, 'files'),
        sharedStorageFeatureEnabled: true,
        sharedStorageDir: '/storage/emulated/0',
        sharedStorageAccessGranted: true,
      );
      final repository = LocalTerminalRepository(
        resolvePaths: () async => paths,
        processFactory:
            ({
              required executable,
              required arguments,
              required environment,
              required rows,
              required columns,
            }) {
              capturedArguments = arguments;
              return _FakePtyProcess();
            },
      );

      await repository.connect(
        SavedHost.localShell(id: 'local'),
        columns: 80,
        rows: 24,
      );

      expect(
        await Directory(paths.androidSharedMountHostPath).exists(),
        isTrue,
      );
      expect(
        capturedArguments,
        containsAllInOrder([
          '-b',
          '/storage/emulated/0:${LocalShellPaths.androidSharedMountPoint}',
        ]),
      );
    });
  });
}

class _FakePtyProcess implements PtyProcess {
  final _output = StreamController<Uint8List>.broadcast();

  @override
  Stream<Uint8List> get output => _output.stream;

  @override
  Future<int> get exitCode => Completer<int>().future;

  @override
  void kill() {}

  @override
  void resize(int rows, int columns) {}

  @override
  void write(Uint8List data) {}
}

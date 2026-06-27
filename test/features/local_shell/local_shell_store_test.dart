import 'dart:io';

import 'package:conduit/features/local_shell/data/local_shell_store.dart';
import 'package:conduit/features/local_shell/domain/local_shell_paths.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('LocalShellStore', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('conduit_store_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('diskUsageBytes skips unreadable rootfs directories', () async {
      final paths = LocalShellPaths(
        nativeLibraryDir: tempDir.path,
        dataDir: tempDir.path,
      );
      final readableFile = File(p.join(paths.installRoot, 'rootfs', 'ok.txt'));
      await readableFile.create(recursive: true);
      await readableFile.writeAsString('hello');

      final restricted = Directory(
        p.join(paths.rootfsDir, 'run', 'systemd', 'dissect-root'),
      );
      await restricted.create(recursive: true);
      final hiddenFile = File(p.join(restricted.path, 'hidden.txt'));
      await hiddenFile.writeAsString('hidden');

      await restricted.stat().then((_) => restricted.parent.stat());
      await Process.run('chmod', ['000', restricted.path]);
      try {
        final bytes = await LocalShellStore(paths).diskUsageBytes();
        expect(bytes, greaterThanOrEqualTo(5));
      } finally {
        await Process.run('chmod', ['700', restricted.path]);
      }
    });
  });
}

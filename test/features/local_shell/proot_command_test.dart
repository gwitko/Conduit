import 'package:conduit/features/local_shell/domain/proot_command.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const builder = ProotCommandBuilder(
    prootBinary: '/lib/libproot.so',
    loaderPath: '/lib/libproot_loader.so',
    libraryPath: '/lib',
    tmpDir: '/data/tmp',
  );

  group('ProotCommandBuilder.login', () {
    final command = builder.login(rootfsDir: '/data/rootfs');

    test('executes proot with the loader environment', () {
      expect(command.executable, '/lib/libproot.so');
      expect(command.environment['PROOT_LOADER'], '/lib/libproot_loader.so');
      expect(command.environment['LD_LIBRARY_PATH'], '/lib');
      expect(command.environment['PROOT_TMP_DIR'], '/data/tmp');
    });

    test('fakes root, kills on exit, and maps hardlinks to symlinks', () {
      expect(command.arguments, contains('-0'));
      expect(command.arguments, contains('--kill-on-exit'));
      expect(command.arguments, contains('--link2symlink'));
    });

    test('roots into the rootfs and launches a login shell', () {
      final rootIndex = command.arguments.indexOf('-r');
      expect(rootIndex, greaterThanOrEqualTo(0));
      expect(command.arguments[rootIndex + 1], '/data/rootfs');
      expect(command.arguments, containsAllInOrder(['/bin/bash', '--login']));
    });

    test('passes a custom command through', () {
      final custom = builder.login(
        rootfsDir: '/data/rootfs',
        command: const ['/bin/bash', '-lc', 'echo hi'],
      );
      expect(
        custom.arguments,
        containsAllInOrder(['/bin/bash', '-lc', 'echo hi']),
      );
    });
  });

  group('ProotCommandBuilder.extractTar', () {
    final command = builder.extractTar(
      archivePath: '/data/rootfs.tar.xz',
      rootfsDir: '/data/rootfs',
      tarBinary: '/lib/libtarbin.so',
      xzBinary: '/lib/libxzbin.so',
    );

    test('runs GNU tar as fake-root under proot --link2symlink', () {
      expect(command.arguments, contains('--link2symlink'));
      expect(command.arguments, contains('-0'));
      expect(
        command.arguments,
        containsAllInOrder(['/lib/libtarbin.so', '--delay-directory-restore']),
      );
    });

    test('inflates the .xz via the bundled xz program', () {
      expect(
        command.arguments,
        contains('--use-compress-program=/lib/libxzbin.so'),
      );
    });

    test('extracts into the rootfs, stripping the top-level dir', () {
      final dirIndex = command.arguments.indexOf('-C');
      expect(command.arguments[dirIndex + 1], '/data/rootfs');
      expect(command.arguments, contains('--strip-components=1'));
    });
  });
}

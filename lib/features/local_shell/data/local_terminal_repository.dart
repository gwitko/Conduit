import 'dart:io';

import 'package:conduit/core/app_failure.dart';
import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:conduit/features/local_shell/data/flutter_pty_process.dart';
import 'package:conduit/features/local_shell/data/local_terminal_session.dart';
import 'package:conduit/features/local_shell/domain/local_shell_paths.dart';
import 'package:conduit/features/local_shell/domain/proot_command.dart';
import 'package:conduit/features/local_shell/domain/pty_process.dart';
import 'package:conduit/features/terminal/domain/ssh_terminal_repository.dart';
import 'package:conduit/features/terminal/domain/ssh_terminal_session.dart';

typedef PtyProcessFactory =
    PtyProcess Function({
      required String executable,
      required List<String> arguments,
      required Map<String, String> environment,
      required int rows,
      required int columns,
    });

class LocalTerminalRepository implements SshTerminalRepository {
  LocalTerminalRepository({
    required this.resolvePaths,
    PtyProcessFactory? processFactory,
  }) : _processFactory = processFactory ?? _defaultProcessFactory;

  final Future<LocalShellPaths> Function() resolvePaths;
  final PtyProcessFactory _processFactory;

  static PtyProcess _defaultProcessFactory({
    required String executable,
    required List<String> arguments,
    required Map<String, String> environment,
    required int rows,
    required int columns,
  }) {
    return FlutterPtyProcess.start(
      executable: executable,
      arguments: arguments,
      environment: environment,
      rows: rows,
      columns: columns,
    );
  }

  @override
  Future<SshTerminalSession> connect(
    SavedHost host, {
    required int columns,
    required int rows,
  }) async {
    try {
      final paths = await resolvePaths();
      final bindMounts = await _prepareBindMounts(paths);
      final command = ProotCommandBuilder(
        prootBinary: paths.prootBinary,
        loaderPath: paths.loaderPath,
        libraryPath: paths.nativeLibraryDir,
        tmpDir: paths.tmpDir,
        bindMounts: bindMounts,
      ).login(rootfsDir: paths.rootfsDir);

      final process = _processFactory(
        executable: command.executable,
        arguments: command.arguments,
        environment: command.environment,
        rows: rows,
        columns: columns,
      );
      return LocalTerminalSession(process);
    } on AppFailure {
      rethrow;
    } catch (error) {
      throw AppFailure('Could not start the local Arch Linux shell.', '$error');
    }
  }

  Future<Map<String, String>> _prepareBindMounts(LocalShellPaths paths) async {
    if (!paths.canMountSharedStorage) {
      return const {};
    }
    await Directory(paths.androidSharedMountHostPath).create(recursive: true);
    return {paths.sharedStorageDir: LocalShellPaths.androidSharedMountPoint};
  }
}

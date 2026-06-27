import 'package:conduit/features/local_shell/data/proot_runner.dart';
import 'package:conduit/features/local_shell/domain/local_shell_paths.dart';
import 'package:conduit/features/local_shell/domain/proot_command.dart';

class ExtractionException implements Exception {
  const ExtractionException(this.message);

  final String message;

  @override
  String toString() => 'ExtractionException($message)';
}

abstract interface class RootfsExtractor {
  Future<void> extract();
}

class ProotRootfsExtractor implements RootfsExtractor {
  ProotRootfsExtractor(this.paths);

  final LocalShellPaths paths;

  @override
  Future<void> extract() async {
    final command =
        ProotCommandBuilder(
          prootBinary: paths.prootBinary,
          loaderPath: paths.loaderPath,
          libraryPath: paths.nativeLibraryDir,
          tmpDir: paths.tmpDir,
        ).extractTar(
          archivePath: paths.downloadPath,
          rootfsDir: paths.rootfsDir,
          tarBinary: paths.tarBinary,
          xzBinary: paths.xzBinary,
        );

    final ProotRunResult result;
    try {
      result = await runProot(command);
    } catch (error) {
      throw ExtractionException('Could not launch proot/tar: $error');
    }

    if (result.exitCode != 0) {
      throw ExtractionException(
        'tar exited with ${result.exitCode}: ${result.stderr}',
      );
    }
  }
}

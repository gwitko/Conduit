import 'package:conduit/features/local_shell/data/proot_runner.dart';
import 'package:conduit/features/local_shell/domain/first_boot_script.dart';
import 'package:conduit/features/local_shell/domain/local_shell_paths.dart';
import 'package:conduit/features/local_shell/domain/proot_command.dart';
import 'package:conduit/features/local_shell/domain/rootfs_manifest.dart';

class FirstBootException implements Exception {
  const FirstBootException(this.message);

  final String message;

  @override
  String toString() => 'FirstBootException($message)';
}

abstract interface class FirstBootRunner {
  Future<void> run(RootfsManifest manifest);
}

class ProotFirstBootRunner implements FirstBootRunner {
  ProotFirstBootRunner(
    this.paths, [
    this.scriptGenerator = const FirstBootScript(),
  ]);

  final LocalShellPaths paths;
  final FirstBootScript scriptGenerator;

  @override
  Future<void> run(RootfsManifest manifest) async {
    final script = scriptGenerator.generate(
      FirstBootConfig(
        pacmanMirror: manifest.pacmanMirror,
        keyringName: manifest.keyringName,
        doneMarkerPath: paths.firstBootMarker,
      ),
    );

    final command = ProotCommandBuilder(
      prootBinary: paths.prootBinary,
      loaderPath: paths.loaderPath,
      libraryPath: paths.nativeLibraryDir,
      tmpDir: paths.tmpDir,
    ).runScript(rootfsDir: paths.rootfsDir, script: script);

    final ProotRunResult result;
    try {
      result = await runProot(command);
    } catch (error) {
      throw FirstBootException('Could not launch first-boot shell: $error');
    }

    if (result.exitCode != 0) {
      throw FirstBootException(
        'First-boot configuration exited with ${result.exitCode}: '
        '${result.stderr}',
      );
    }
  }
}

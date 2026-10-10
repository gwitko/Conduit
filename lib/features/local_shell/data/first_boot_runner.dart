
import 'package:conduit/core/l10n/l10n.dart';
import 'package:conduit/features/local_shell/data/proot_runner.dart';
import 'package:conduit/features/local_shell/domain/first_boot_script.dart';
import 'package:conduit/features/local_shell/domain/local_shell_distro.dart';
import 'package:conduit/features/local_shell/domain/local_shell_paths.dart';
import 'package:conduit/features/local_shell/domain/proot_command.dart';

class FirstBootException implements Exception {
  const FirstBootException(this.message);

  final String message;

  @override
  String toString() => 'FirstBootException($message)';
}

abstract interface class FirstBootRunner {
  Future<void> run(LocalShellDistro distro);
}

class ProotFirstBootRunner implements FirstBootRunner {
  ProotFirstBootRunner(
    this.paths, [
    this.scriptGenerator = const FirstBootScript(),
  ]);

  final LocalShellPaths paths;
  final FirstBootScript scriptGenerator;

  @override
  Future<void> run(LocalShellDistro distro) async {
    final script = scriptGenerator.generate(
      FirstBootConfig(
        distroName: distro.name,
        updateCommand: distro.updateCommand,
        setupCommands: distro.setupCommands,
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
      throw FirstBootException(AppLocalizationsHolder.current.localShellErrorFirstBootLaunch('$error'));
    }

    if (result.exitCode != 0) {
      throw FirstBootException(
        AppLocalizationsHolder.current.localShellErrorFirstBootExit(
          '${result.exitCode}',
          result.stderr,
        ),
      );
    }
  }
}

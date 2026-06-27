import 'package:conduit/features/local_shell/domain/local_shell_event.dart';
import 'package:conduit/features/local_shell/domain/local_shell_state.dart';
import 'package:conduit/features/local_shell/domain/local_shell_state_machine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const machine = LocalShellStateMachine();
  const initial = LocalShellState.initial;
  const notInstalled = LocalShellState.notInstalled;

  group('LocalShellStateMachine', () {
    test('initial state checks before showing install', () {
      expect(initial.stage, LocalShellStage.checking);
      expect(initial.canInstall, isFalse);
    });

    test('install request begins downloading at zero progress', () {
      final next = machine.reduce(notInstalled, const InstallRequested());
      expect(next.stage, LocalShellStage.downloading);
      expect(next.progress, 0);
    });

    test('download progress updates only while downloading', () {
      final downloading = machine.reduce(
        notInstalled,
        const InstallRequested(),
      );
      final progressed = machine.reduce(
        downloading,
        const DownloadProgressed(0.5),
      );
      expect(progressed.progress, 0.5);

      final ignored = machine.reduce(
        notInstalled,
        const DownloadProgressed(0.5),
      );
      expect(ignored, notInstalled);
    });

    test('progress is clamped to 0..1', () {
      final downloading = machine.reduce(
        notInstalled,
        const InstallRequested(),
      );
      expect(
        machine.reduce(downloading, const DownloadProgressed(2)).progress,
        1.0,
      );
      expect(
        machine.reduce(downloading, const DownloadProgressed(-1)).progress,
        0.0,
      );
    });

    test('full install path reaches ready', () {
      var state = machine.reduce(notInstalled, const InstallRequested());
      state = machine.reduce(state, const DownloadFinished());
      expect(state.stage, LocalShellStage.extracting);
      state = machine.reduce(state, const ExtractFinished());
      expect(state.stage, LocalShellStage.configuring);
      state = machine.reduce(
        state,
        const InstallSucceeded(version: '2026.06', diskUsageBytes: 1234),
      );
      expect(state.stage, LocalShellStage.ready);
      expect(state.installedVersion, '2026.06');
      expect(state.diskUsageBytes, 1234);
      expect(state.isReady, isTrue);
    });

    test('stage transitions ignore out-of-order finish events', () {
      expect(
        machine.reduce(notInstalled, const DownloadFinished()),
        notInstalled,
      );
      expect(
        machine.reduce(notInstalled, const ExtractFinished()),
        notInstalled,
      );
    });

    test('failure carries the error and is installable again', () {
      final downloading = machine.reduce(
        notInstalled,
        const InstallRequested(),
      );
      const error = LocalShellError(LocalShellErrorKind.network, 'offline');
      final failed = machine.reduce(downloading, const InstallFailed(error));
      expect(failed.stage, LocalShellStage.failed);
      expect(failed.error, error);
      expect(failed.canInstall, isTrue);
    });

    test('unsupported device is sticky against environment probes', () {
      final unsupported = machine.reduce(
        initial,
        const DeviceUnsupported('no arm64'),
      );
      expect(unsupported.stage, LocalShellStage.unsupported);
      expect(
        machine.reduce(unsupported, const EnvironmentMissing()),
        unsupported,
      );
      expect(
        machine.reduce(unsupported, const EnvironmentReady(version: 'x')),
        unsupported,
      );
    });

    test('environment probes set ready / not-installed', () {
      final ready = machine.reduce(
        initial,
        const EnvironmentReady(version: '2026.06', diskUsageBytes: 10),
      );
      expect(ready.stage, LocalShellStage.ready);
      expect(
        machine.reduce(ready, const EnvironmentMissing()).stage,
        LocalShellStage.notInstalled,
      );
    });

    test('reset returns to the not-installed state', () {
      final ready = machine.reduce(
        initial,
        const EnvironmentReady(version: 'x'),
      );
      expect(machine.reduce(ready, const ResetRequested()), notInstalled);
    });
  });
}

import 'dart:async';
import 'dart:io';

import 'package:conduit/features/local_shell/data/local_shell_platform.dart';
import 'package:conduit/features/local_shell/data/rootfs_manifest_source.dart';
import 'package:conduit/features/local_shell/domain/local_shell_state.dart';
import 'package:conduit/features/local_shell/domain/rootfs_manifest.dart';
import 'package:conduit/features/local_shell/presentation/local_shell_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeLocalShellPlatform extends LocalShellPlatform {
  FakeLocalShellPlatform(this.environment);

  final FutureOr<LocalShellEnvironment?> Function() environment;
  int loadCount = 0;

  @override
  Future<LocalShellEnvironment?> load() async {
    loadCount++;
    return environment();
  }
}

class ThrowingManifestSource implements RootfsManifestSource {
  const ThrowingManifestSource();

  @override
  Future<RootfsManifest> fetch() {
    throw const FormatException('test manifest failure');
  }
}

void main() {
  group('LocalShellController', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('conduit_shell_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'install waits for an in-flight probe before deciding support',
      () async {
        final probe = Completer<LocalShellEnvironment?>();
        final platform = FakeLocalShellPlatform(() => probe.future);
        final controller = LocalShellController(
          platform: platform,
          manifestSource: const ThrowingManifestSource(),
        );

        unawaited(controller.refresh());
        final install = controller.install();
        await Future<void>.delayed(Duration.zero);

        probe.complete(
          LocalShellEnvironment(
            nativeLibraryDir: tempDir.path,
            filesDir: tempDir.path,
            supportedAbis: const ['arm64-v8a'],
          ),
        );
        await install;

        expect(platform.loadCount, 1);
        expect(controller.state.stage, LocalShellStage.failed);
        expect(
          controller.state.error?.kind,
          isNot(LocalShellErrorKind.unsupportedDevice),
        );
      },
    );
  });
}

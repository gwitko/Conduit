import 'dart:io';

import 'package:conduit/core/app_failure.dart';
import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:conduit/features/local_shell/data/first_boot_runner.dart';
import 'package:conduit/features/local_shell/data/local_shell_platform.dart';
import 'package:conduit/features/local_shell/data/local_shell_store.dart';
import 'package:conduit/features/local_shell/data/rootfs_downloader.dart';
import 'package:conduit/features/local_shell/data/rootfs_extractor.dart';
import 'package:conduit/features/local_shell/data/rootfs_manifest_source.dart';
import 'package:conduit/features/local_shell/domain/local_shell_event.dart';
import 'package:conduit/features/local_shell/domain/local_shell_paths.dart';
import 'package:conduit/features/local_shell/domain/local_shell_state.dart';
import 'package:conduit/features/local_shell/domain/local_shell_state_machine.dart';
import 'package:conduit/features/local_shell/local_shell_config.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const String localShellHostId = '__conduit_local_shell__';

class LocalShellController extends ChangeNotifier {
  LocalShellController({
    RootfsManifestSource? manifestSource,
    this.platform = const LocalShellPlatform(),
    this.httpClient,
    this.machine = const LocalShellStateMachine(),
  }) : manifestSource =
           manifestSource ??
           EmbeddedRootfsManifestSource(defaultRootfsManifest());

  final RootfsManifestSource manifestSource;
  final LocalShellPlatform platform;
  final http.Client? httpClient;
  final LocalShellStateMachine machine;

  LocalShellState _state = LocalShellState.initial;
  LocalShellState get state => _state;

  LocalShellEnvironment? _environment;
  LocalShellPaths? _paths;
  Future<void>? _probeFuture;

  SavedHost localHost() => SavedHost.localShell(id: localShellHostId);

  Future<LocalShellPaths> requirePaths() async {
    final paths = _paths;
    if (paths == null) {
      throw const AppFailure('The local shell is not installed.');
    }
    return paths;
  }

  void _dispatch(LocalShellEvent event) {
    final next = machine.reduce(_state, event);
    if (next == _state) return;
    _state = next;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_state.isBusy) return;
    final existingProbe = _probeFuture;
    if (existingProbe != null) return existingProbe;

    final probe = _refresh();
    _probeFuture = probe;
    try {
      await probe;
    } finally {
      if (identical(_probeFuture, probe)) {
        _probeFuture = null;
      }
    }
  }

  Future<void> _refresh() async {
    try {
      final env = await platform.load();
      _environment = env;
      if (env == null) {
        _paths = null;
        _dispatch(
          const DeviceUnsupported(
            'The local shell is only available on Android.',
          ),
        );
        return;
      }
      if (!env.isUsable) {
        _paths = null;
        _dispatch(
          const DeviceUnsupported(
            'The local shell requires a 64-bit ARM (arm64-v8a) device.',
          ),
        );
        return;
      }

      final paths = LocalShellPaths(
        nativeLibraryDir: env.nativeLibraryDir,
        dataDir: env.filesDir,
      );
      _paths = paths;
      final store = LocalShellStore(paths);
      if (await store.isConfigured()) {
        _dispatch(
          EnvironmentReady(
            version: await store.installedVersion() ?? 'unknown',
            diskUsageBytes: await store.diskUsageBytes(),
          ),
        );
      } else {
        _dispatch(const EnvironmentMissing());
      }
    } catch (error) {
      _dispatch(InstallFailed(_mapError(error)));
    }
  }

  Future<void> install() async {
    if (_state.isChecking) {
      await refresh();
    }
    if (!_state.canInstall) return;
    if (_paths == null || _environment == null) {
      await refresh();
    }
    final paths = _paths;
    final env = _environment;
    if (paths == null || env == null || !env.isUsable) {
      _dispatch(
        const DeviceUnsupported(
          'The local shell requires a 64-bit ARM (arm64-v8a) device.',
        ),
      );
      return;
    }

    _dispatch(const InstallRequested());
    try {
      final manifest = await manifestSource.fetch();

      final store = LocalShellStore(paths);
      await store.prepareDirectories();

      await HttpRootfsDownloader(httpClient).download(
        manifest: manifest,
        destination: paths.downloadPath,
        onProgress: (progress) => _dispatch(DownloadProgressed(progress)),
      );
      _dispatch(const DownloadFinished());

      await store.resetRootfs();
      await ProotRootfsExtractor(paths).extract();
      await store.deleteDownload();
      _dispatch(const ExtractFinished());

      _dispatch(const ConfigureStarted());
      await ProotFirstBootRunner(paths).run(manifest);

      await store.writeVersion(manifest.version);
      _dispatch(
        InstallSucceeded(
          version: manifest.version,
          diskUsageBytes: await store.diskUsageBytes(),
        ),
      );
    } catch (error) {
      _dispatch(InstallFailed(_mapError(error)));
    }
  }

  Future<void> reinstall() async {
    if (_state.isBusy) return;
    await reset();
    await install();
  }

  Future<void> reset() async {
    final paths = _paths;
    if (paths == null || _state.isBusy) return;
    try {
      await LocalShellStore(paths).wipe();
    } catch (_) {}
    _dispatch(const ResetRequested());
  }

  LocalShellError _mapError(Object error) {
    if (error is DownloadException) {
      return LocalShellError(switch (error.kind) {
        DownloadFailureKind.network => LocalShellErrorKind.network,
        DownloadFailureKind.lowDisk => LocalShellErrorKind.lowDisk,
        DownloadFailureKind.corrupt => LocalShellErrorKind.corruptDownload,
        DownloadFailureKind.unknown => LocalShellErrorKind.unknown,
      }, error.message);
    }
    if (error is ExtractionException) {
      return LocalShellError(
        LocalShellErrorKind.extractionFailed,
        error.message,
      );
    }
    if (error is FirstBootException) {
      return LocalShellError(LocalShellErrorKind.keyringFailed, error.message);
    }
    if (error is http.ClientException || error is SocketException) {
      return LocalShellError(LocalShellErrorKind.network, '$error');
    }
    if (error is FormatException) {
      return LocalShellError(
        LocalShellErrorKind.network,
        'Invalid rootfs manifest: ${error.message}',
      );
    }
    return LocalShellError(LocalShellErrorKind.unknown, '$error');
  }
}

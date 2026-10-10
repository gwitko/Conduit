import 'dart:io';

import 'package:conduit/core/app_failure.dart';
import 'package:conduit/core/l10n/l10n.dart';
import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:conduit/features/local_shell/data/first_boot_runner.dart';
import 'package:conduit/features/local_shell/data/local_shell_instance_store.dart';
import 'package:conduit/features/local_shell/data/local_shell_platform.dart';
import 'package:conduit/features/local_shell/data/local_shell_store.dart';
import 'package:conduit/features/local_shell/data/rootfs_downloader.dart';
import 'package:conduit/features/local_shell/data/rootfs_extractor.dart';
import 'package:conduit/features/local_shell/domain/local_shell_distro.dart';
import 'package:conduit/features/local_shell/domain/local_shell_event.dart';
import 'package:conduit/features/local_shell/domain/local_shell_instance.dart';
import 'package:conduit/features/local_shell/domain/local_shell_paths.dart';
import 'package:conduit/features/local_shell/domain/local_shell_state.dart';
import 'package:conduit/features/local_shell/domain/local_shell_state_machine.dart';
import 'package:conduit/features/local_shell/local_shell_config.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

const String localShellHostId = '__conduit_local_shell__';

String localShellHostIdFor(String instanceId) => '$localShellHostId$instanceId';

String? localShellInstanceIdFromHostId(String hostId) {
  if (!hostId.startsWith(localShellHostId)) return null;
  final rest = hostId.substring(localShellHostId.length);
  final separator = rest.indexOf('#');
  return separator == -1 ? rest : rest.substring(0, separator);
}

class LocalShellController extends ChangeNotifier {
  LocalShellController({
    List<LocalShellDistro>? catalog,
    this.platform = const LocalShellPlatform(),
    this.httpClient,
    this.machine = const LocalShellStateMachine(),
  }) : catalog = catalog ?? defaultLocalShellDistros();

  final List<LocalShellDistro> catalog;
  final LocalShellPlatform platform;
  final http.Client? httpClient;
  final LocalShellStateMachine machine;

  final Map<String, LocalShellState> _states = {};
  List<LocalShellInstance> _instances = [];
  LocalShellEnvironment? _environment;
  String? _unsupportedMessage;
  bool _probed = false;
  String? _lastOpenedInstanceId;
  Future<void>? _probeFuture;

  List<LocalShellInstance> get instances => List.unmodifiable(_instances);

  bool get isChecking => !_probed;

  bool get isUnsupported => _unsupportedMessage != null;

  String? get unsupportedMessage => _unsupportedMessage;

  bool get anyBusy => _states.values.any((state) => state.isBusy);

  LocalShellState stateFor(String instanceId) =>
      _states[instanceId] ?? LocalShellState.initial;

  LocalShellState get state {
    final message = _unsupportedMessage;
    if (message != null) {
      return LocalShellState(
        stage: LocalShellStage.unsupported,
        error: LocalShellError(LocalShellErrorKind.unsupportedDevice, message),
      );
    }
    if (!_probed) return LocalShellState.initial;
    final instance = defaultInstance;
    if (instance == null) return LocalShellState.notInstalled;
    return stateFor(instance.id);
  }

  LocalShellDistro? distroById(String distroId) {
    for (final distro in catalog) {
      if (distro.id == distroId) return distro;
    }
    return null;
  }

  LocalShellInstance? instanceById(String instanceId) {
    for (final instance in _instances) {
      if (instance.id == instanceId) return instance;
    }
    return null;
  }

  LocalShellInstance? get defaultInstance {
    for (final instance in _instances) {
      if (stateFor(instance.id).isBusy) return instance;
    }
    final lastOpened = _lastOpenedInstanceId;
    if (lastOpened != null) {
      final instance = instanceById(lastOpened);
      if (instance != null && stateFor(instance.id).isReady) return instance;
    }
    for (final instance in _instances) {
      if (stateFor(instance.id).isReady) return instance;
    }
    return _instances.isEmpty ? null : _instances.first;
  }

  bool get sharedStorageAccessGranted =>
      _environment?.sharedStorageAccessGranted ?? false;
  bool get sharedStorageFeatureEnabled =>
      _environment?.sharedStorageFeatureEnabled ?? false;

  SavedHost localHost(
    LocalShellInstance instance, {
    int sessionNumber = 1,
  }) => SavedHost.localShell(
    id:
        '${localShellHostIdFor(instance.id)}'
        '${sessionNumber <= 1 ? '' : '#${DateTime.now().microsecondsSinceEpoch}'}',
    name: sessionNumber <= 1
        ? instance.name
        : '${instance.name} ($sessionNumber)',
  );

  LocalShellInstanceStore? get _instanceStore {
    final env = _environment;
    if (env == null || !env.isUsable) return null;
    return LocalShellInstanceStore(dataDir: env.filesDir, catalog: catalog);
  }

  LocalShellPaths? _pathsFor(String instanceId) {
    final env = _environment;
    if (env == null || !env.isUsable) return null;
    return LocalShellPaths(
      instanceId: instanceId,
      nativeLibraryDir: env.nativeLibraryDir,
      dataDir: env.filesDir,
      sharedStorageFeatureEnabled: env.sharedStorageFeatureEnabled,
      sharedStorageDir: env.sharedStorageDir,
      sharedStorageAccessGranted: env.sharedStorageAccessGranted,
    );
  }

  Future<LocalShellLaunch> requireLaunch(String hostId) async {
    final instanceId = localShellInstanceIdFromHostId(hostId) ?? hostId;
    final instance = instanceById(instanceId);
    final distro = instance == null ? null : distroById(instance.distroId);
    final paths = _pathsFor(instanceId);
    if (distro == null || paths == null) {
      throw AppFailure(AppLocalizationsHolder.current.localShellErrorNotInstalled);
    }
    return LocalShellLaunch(distro: distro, paths: paths);
  }

  String? get _lastOpenedFilePath {
    final env = _environment;
    if (env == null || env.filesDir.isEmpty) return null;
    return p.join(env.filesDir, '.local_shell_last_distro');
  }

  Future<void> markOpened(String instanceId) async {
    _lastOpenedInstanceId = instanceId;
    notifyListeners();
    final path = _lastOpenedFilePath;
    if (path == null) return;
    try {
      await File(path).writeAsString(instanceId);
    } catch (_) {}
  }

  Future<void> _loadLastOpened() async {
    final path = _lastOpenedFilePath;
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        final id = (await file.readAsString()).trim();
        if (id.isNotEmpty) _lastOpenedInstanceId = id;
      }
    } catch (_) {}
  }

  void _dispatch(String instanceId, LocalShellEvent event) {
    final current = stateFor(instanceId);
    final next = machine.reduce(current, event);
    if (next == current) return;
    _states[instanceId] = next;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (anyBusy) return;
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
        _setUnsupported(AppLocalizationsHolder.current.localShellErrorAndroidOnly);
        return;
      }
      if (!env.isUsable) {
        _setUnsupported(
          AppLocalizationsHolder.current.localShellErrorArm64Only,
        );
        return;
      }

      _unsupportedMessage = null;
      await _loadLastOpened();
      final store = _instanceStore;
      if (store != null) {
        _instances = await store.discover();
      }
      for (final instance in _instances) {
        final paths = _pathsFor(instance.id);
        if (paths == null) continue;
        final installStore = LocalShellStore(paths);
        if (await installStore.isConfigured()) {
          _dispatch(
            instance.id,
            EnvironmentReady(
              version: await installStore.installedVersion() ?? 'unknown',
              diskUsageBytes: await installStore.diskUsageBytes(),
            ),
          );
        } else {
          _dispatch(instance.id, const EnvironmentMissing());
        }
      }
      _probed = true;
      notifyListeners();
    } catch (error) {
      _probed = true;
      for (final instance in _instances) {
        _dispatch(instance.id, InstallFailed(_mapError(error)));
      }
      notifyListeners();
    }
  }

  void _setUnsupported(String message) {
    _probed = true;
    _unsupportedMessage = message;
    _instances = [];
    _states.clear();
    notifyListeners();
  }

  Future<void> installNew(String distroId, {String? name}) async {
    if (anyBusy) return;
    if (!_probed) await refresh();
    final distro = distroById(distroId);
    final store = _instanceStore;
    if (distro == null || store == null) return;

    final instance = await store.createInstance(distro, name: name);
    _instances = [..._instances, instance];
    notifyListeners();
    await _runInstall(instance);
  }

  Future<void> install(String instanceId) async {
    if (anyBusy || !stateFor(instanceId).canInstall) return;
    final instance = instanceById(instanceId);
    if (instance == null) return;
    await _runInstall(instance);
  }

  Future<void> reinstall(String instanceId) async {
    if (anyBusy) return;
    final instance = instanceById(instanceId);
    final paths = _pathsFor(instanceId);
    if (instance == null || paths == null) return;
    try {
      await LocalShellStore(paths).wipe();
    } catch (_) {}
    _dispatch(instanceId, const ResetRequested());
    await _runInstall(instance);
  }

  Future<void> remove(String instanceId) async {
    final paths = _pathsFor(instanceId);
    if (paths == null || anyBusy) return;
    try {
      await LocalShellStore(paths).wipe();
    } catch (_) {}
    _instances = [
      for (final instance in _instances)
        if (instance.id != instanceId) instance,
    ];
    _states.remove(instanceId);
    if (_lastOpenedInstanceId == instanceId) {
      _lastOpenedInstanceId = null;
    }
    notifyListeners();
  }

  Future<void> rename(String instanceId, String name) async {
    final trimmed = name.trim();
    final instance = instanceById(instanceId);
    final store = _instanceStore;
    if (instance == null || store == null || trimmed.isEmpty) return;
    final renamed = instance.copyWith(name: trimmed);
    _instances = [
      for (final entry in _instances) entry.id == instanceId ? renamed : entry,
    ];
    notifyListeners();
    try {
      await store.writeMeta(renamed);
    } catch (_) {}
  }

  Future<void> _runInstall(LocalShellInstance instance) async {
    final distro = distroById(instance.distroId);
    final paths = _pathsFor(instance.id);
    final instanceStore = _instanceStore;
    if (distro == null || paths == null || instanceStore == null) {
      _setUnsupported(
        AppLocalizationsHolder.current.localShellErrorArm64Only,
      );
      return;
    }

    _dispatch(instance.id, InstallRequested(distroName: instance.name));
    try {
      final manifest = distro.manifest;

      final store = LocalShellStore(paths);
      await store.prepareDirectories();
      await instanceStore.writeMeta(instance);

      await HttpRootfsDownloader(httpClient).download(
        manifest: manifest,
        destination: paths.downloadPath,
        onProgress: (progress) =>
            _dispatch(instance.id, DownloadProgressed(progress)),
      );
      _dispatch(instance.id, const DownloadFinished());

      await store.resetRootfs();
      await ProotRootfsExtractor(paths).extract();
      await store.deleteDownload();
      _dispatch(instance.id, const ExtractFinished());

      _dispatch(instance.id, const ConfigureStarted());
      await ProotFirstBootRunner(paths).run(distro);

      await store.writeVersion(manifest.version);
      _dispatch(
        instance.id,
        InstallSucceeded(
          version: manifest.version,
          diskUsageBytes: await store.diskUsageBytes(),
        ),
      );
    } catch (error) {
      _dispatch(instance.id, InstallFailed(_mapError(error)));
    }
  }

  Future<void> requestSharedStorageAccess() async {
    await platform.requestSharedStorageAccess();
    await refresh();
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
      return LocalShellError(
        LocalShellErrorKind.configureFailed,
        error.message,
      );
    }
    if (error is http.ClientException || error is SocketException) {
      return LocalShellError(LocalShellErrorKind.network, '$error');
    }
    return LocalShellError(LocalShellErrorKind.unknown, '$error');
  }
}

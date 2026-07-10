import 'package:conduit/core/app_failure.dart';
import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:conduit/features/hosts/domain/saved_hosts_repository.dart';
import 'package:flutter/foundation.dart';

class HostsController extends ChangeNotifier {
  HostsController(this._repository);

  final SavedHostsRepository _repository;

  List<SavedHost> _hosts = const [];
  List<SavedHost>? _sortedHostsCache;
  HostListSortMode _sortMode = HostListSortMode.lastConnected;
  List<String> _manualOrder = const [];
  bool _isLoading = true;
  String? _errorMessage;

  List<SavedHost> get hosts => _hosts;
  List<SavedHost> get sortedHosts =>
      _sortedHostsCache ??= _computeSortedHosts();
  HostListSortMode get sortMode => _sortMode;
  List<String> get manualOrder => List.unmodifiable(_manualOrder);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final hosts = await _repository.loadHosts();
      _sortMode = await _repository.loadSortMode();
      _manualOrder = await _repository.loadManualOrder();
      _setHosts(hosts);
    } on AppFailure catch (failure) {
      _errorMessage = failure.toString();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setSortMode(HostListSortMode mode) async {
    if (mode == _sortMode) return;

    final seedManualOrder =
        mode == HostListSortMode.manual && _manualOrder.isEmpty;
    if (seedManualOrder) {
      _manualOrder = sortedHosts.map((host) => host.id).toList();
    }

    _sortMode = mode;
    _sortedHostsCache = null;
    notifyListeners();

    try {
      await _repository.saveSortMode(mode);
      if (seedManualOrder) {
        await _repository.saveManualOrder(_manualOrder);
      }
    } on AppFailure catch (failure) {
      _errorMessage = failure.toString();
      notifyListeners();
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
    }
  }

  Future<void> reorderManual(int oldIndex, int newIndex) async {
    final ordered = [...sortedHosts];
    if (oldIndex < 0 || oldIndex >= ordered.length) return;
    newIndex = newIndex.clamp(0, ordered.length - 1);
    if (oldIndex == newIndex) return;

    final moved = ordered.removeAt(oldIndex);
    ordered.insert(newIndex, moved);
    _manualOrder = ordered.map((host) => host.id).toList();
    _sortMode = HostListSortMode.manual;
    _sortedHostsCache = null;
    notifyListeners();

    try {
      await _repository.saveManualOrder(_manualOrder);
    } on AppFailure catch (failure) {
      _errorMessage = failure.toString();
      notifyListeners();
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
    }
  }

  Future<void> upsert(SavedHost host) async {
    final index = _hosts.indexWhere((currentHost) => currentHost.id == host.id);
    final updatedHosts = [..._hosts];

    if (index == -1) {
      updatedHosts.add(host);
    } else {
      updatedHosts[index] = host;
    }

    await _save(updatedHosts);
  }

  Future<void> mergeImported({
    required List<SavedHost> hosts,
    required HostListSortMode sortMode,
    required List<String> manualOrder,
  }) async {
    final mergedById = {for (final host in _hosts) host.id: host};
    for (final host in hosts) {
      if (host.id.isNotEmpty) {
        mergedById[host.id] = host;
      }
    }

    _errorMessage = null;
    notifyListeners();

    try {
      final mergedHosts = mergedById.values.toList(growable: false);
      final importedIds = hosts.map((host) => host.id).toSet();
      final currentManualOrder = _manualOrder.where(mergedById.containsKey);
      final mergedManualOrder = <String>[
        ...manualOrder.where(mergedById.containsKey),
        ...currentManualOrder.where((id) => !importedIds.contains(id)),
        ...mergedById.keys.where(
          (id) => !manualOrder.contains(id) && !_manualOrder.contains(id),
        ),
      ];
      await _repository.saveHosts(mergedHosts);
      await _repository.saveSortMode(sortMode);
      await _repository.saveManualOrder(mergedManualOrder);
      _sortMode = sortMode;
      _manualOrder = mergedManualOrder;
      _setHosts(mergedHosts);
    } on AppFailure catch (failure) {
      _errorMessage = failure.toString();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> remove(SavedHost host) async {
    await _save(
      _hosts.where((currentHost) => currentHost.id != host.id).toList(),
    );
  }

  Future<void> markConnected(SavedHost host) async {
    final current = _hosts.firstWhere(
      (currentHost) => currentHost.id == host.id,
      orElse: () => host,
    );
    await upsert(current.copyWith(lastConnectedAt: DateTime.now()));
  }

  Future<void> _save(List<SavedHost> hosts) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.saveHosts(hosts);
      _setHosts(hosts);
    } on AppFailure catch (failure) {
      _errorMessage = failure.toString();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      notifyListeners();
    }
  }

  void _setHosts(List<SavedHost> hosts) {
    _hosts = hosts;
    _sortedHostsCache = null;
  }

  List<SavedHost> _computeSortedHosts() {
    final sorted = [..._hosts];
    switch (_sortMode) {
      case HostListSortMode.lastConnected:
        sorted.sort(_compareLastConnected);
      case HostListSortMode.name:
        sorted.sort(_compareName);
      case HostListSortMode.added:
        break;
      case HostListSortMode.manual:
        return _computeManualOrder();
    }
    return List.unmodifiable(sorted);
  }

  List<SavedHost> _computeManualOrder() {
    final byId = {for (final host in _hosts) host.id: host};
    final ordered = <SavedHost>[];
    final seen = <String>{};
    for (final id in _manualOrder) {
      final host = byId[id];
      if (host != null && seen.add(id)) {
        ordered.add(host);
      }
    }
    for (final host in _hosts) {
      if (seen.add(host.id)) {
        ordered.add(host);
      }
    }
    return List.unmodifiable(ordered);
  }

  int _compareLastConnected(SavedHost a, SavedHost b) {
    final aDate = a.lastConnectedAt;
    final bDate = b.lastConnectedAt;
    if (aDate == null && bDate == null) {
      return _compareName(a, b);
    }
    if (aDate == null) {
      return 1;
    }
    if (bDate == null) {
      return -1;
    }
    final byDate = bDate.compareTo(aDate);
    return byDate == 0 ? _compareName(a, b) : byDate;
  }

  int _compareName(SavedHost a, SavedHost b) {
    final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    if (byName != 0) return byName;
    final byHost = a.host.toLowerCase().compareTo(b.host.toLowerCase());
    if (byHost != 0) return byHost;
    return a.id.compareTo(b.id);
  }
}

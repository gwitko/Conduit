import 'dart:async';

import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:conduit/features/sftp/domain/remote_file_kind.dart';
import 'package:conduit/features/sftp/domain/sftp_repository.dart';
import 'package:conduit/features/sftp/domain/sftp_session.dart';
import 'package:conduit/features/sftp/presentation/file_viewer/sftp_file_viewer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// A file opened from terminal output, shown as a tab beside session tabs.
class TerminalFileTab {
  TerminalFileTab({required this.host, required this.path});

  final SavedHost host;
  final String path;
  final GlobalKey<SftpFileViewerState> viewerKey = GlobalKey();

  String get title => remoteFileName(path);
}

/// Viewer tabs for the terminal workspace, with one pooled SFTP session per
/// host that is closed when the host's last tab closes.
class TerminalFileTabsController extends ChangeNotifier {
  TerminalFileTabsController(this._repository);

  final SftpRepository _repository;
  final List<TerminalFileTab> _tabs = [];
  final Map<String, Future<SftpSession>> _sessions = {};
  final Map<String, String> _resolvedPaths = {};
  TerminalFileTab? _active;

  List<TerminalFileTab> get tabs => List.unmodifiable(_tabs);
  TerminalFileTab? get active => _active;

  TerminalFileTab open(SavedHost host, String path) {
    final existing = _tabs
        .where((tab) => tab.host.id == host.id && tab.path == path)
        .firstOrNull;
    final tab = existing ?? TerminalFileTab(host: host, path: path);
    if (existing == null) {
      _tabs.add(tab);
    }
    _active = tab;
    notifyListeners();
    return tab;
  }

  void activate(TerminalFileTab? tab) {
    if (tab == _active || (tab != null && !_tabs.contains(tab))) {
      return;
    }
    _active = tab;
    notifyListeners();
  }

  void close(TerminalFileTab tab) {
    if (!_tabs.remove(tab)) {
      return;
    }
    if (_active == tab) {
      _active = null;
    }
    if (_tabs.every((other) => other.host.id != tab.host.id)) {
      _closeSession(tab.host.id);
    }
    notifyListeners();
  }

  Future<Uint8List> read(
    TerminalFileTab tab,
    void Function(int bytesRead, int? total)? onProgress,
  ) async {
    final session = await _session(tab.host);
    final path = await _resolve(session, tab);
    return session.read(path, onProgress: onProgress);
  }

  Future<void> write(TerminalFileTab tab, Uint8List bytes) async {
    final session = await _session(tab.host);
    final path = await _resolve(session, tab);
    await session.write(path, Stream.value(bytes), bytes.length);
  }

  /// Shell output often prints paths relative to `~`; SFTP wants absolute
  /// ones. Resolution happens server-side against the SFTP home directory.
  Future<String> _resolve(SftpSession session, TerminalFileTab tab) async {
    if (tab.path.startsWith('/')) {
      return tab.path;
    }
    final key = '${tab.host.id}:${tab.path}';
    final cached = _resolvedPaths[key];
    if (cached != null) {
      return cached;
    }
    final relative = tab.path.startsWith('~/')
        ? tab.path.substring(2)
        : tab.path;
    final resolved = await session.resolve(relative);
    _resolvedPaths[key] = resolved;
    return resolved;
  }

  Future<SftpSession> _session(SavedHost host) {
    final existing = _sessions[host.id];
    if (existing != null) {
      return existing;
    }
    final future = _repository.connect(host);
    _sessions[host.id] = future;
    // Drop a failed connection from the pool so a viewer retry reconnects.
    unawaited(
      future.then<void>(
        (_) {},
        onError: (Object _) {
          if (identical(_sessions[host.id], future)) {
            _sessions.remove(host.id);
          }
        },
      ),
    );
    return future;
  }

  void _closeSession(String hostId) {
    final future = _sessions.remove(hostId);
    if (future == null) {
      return;
    }
    unawaited(
      future.then<void>((session) => session.close(), onError: (Object _) {}),
    );
  }

  @override
  void dispose() {
    for (final hostId in List.of(_sessions.keys)) {
      _closeSession(hostId);
    }
    _tabs.clear();
    super.dispose();
  }
}

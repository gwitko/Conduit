import 'dart:async';
import 'dart:io';

import 'package:conduit/core/app_failure.dart';
import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:conduit/features/sftp/data/tar_archive_builder.dart';
import 'package:conduit/features/sftp/domain/file_export.dart';
import 'package:conduit/features/sftp/domain/sftp_entry.dart';
import 'package:conduit/features/sftp/domain/sftp_repository.dart';
import 'package:conduit/features/sftp/domain/sftp_session.dart';
import 'package:conduit/features/terminal/domain/security_key_interaction.dart';
import 'package:flutter/foundation.dart';

enum SftpBrowserStatus { connecting, ready, failed }

enum SftpSortMode { name, modified, size, type }

class SftpTransfer {
  const SftpTransfer({
    required this.name,
    required this.isUpload,
    required this.done,
    this.total,
  });

  final String name;
  final bool isUpload;
  final int done;
  final int? total;

  double? get fraction {
    final t = total;
    if (t == null || t <= 0) return null;
    return (done / t).clamp(0.0, 1.0);
  }
}

class SftpUploadFile {
  SftpUploadFile({
    required this.source,
    required this.name,
    required this.size,
  });

  SftpUploadFile.local({
    required String localPath,
    required String name,
    required int size,
  }) : this(source: () => File(localPath).openRead(), name: name, size: size);

  final String name;
  final int size;
  final Stream<List<int>> Function() source;

  Stream<Uint8List> openRead() {
    return source().map(
      (chunk) => chunk is Uint8List ? chunk : Uint8List.fromList(chunk),
    );
  }
}

class SftpBrowserController extends ChangeNotifier {
  SftpBrowserController({
    required this.host,
    required this.repository,
    required this.fileExport,
  });

  final SavedHost host;
  final SftpRepository repository;
  final FileExport fileExport;

  SftpSession? _session;
  SftpBrowserStatus _status = SftpBrowserStatus.connecting;
  String? _errorMessage;
  String _path = '/';
  List<SftpEntry> _entries = const [];
  String _searchQuery = '';
  SftpSortMode _sortMode = SftpSortMode.name;
  bool _busy = false;
  SftpTransfer? _transfer;
  String? _securityKeyMessage;
  StreamSubscription<String>? _securityKeySubscription;
  bool _disposed = false;

  SftpBrowserStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String get path => _path;
  List<SftpEntry> get entries => _entries;
  String get searchQuery => _searchQuery;
  SftpSortMode get sortMode => _sortMode;
  List<SftpEntry> get visibleEntries {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = query.isEmpty
        ? List<SftpEntry>.of(_entries)
        : _entries.where((entry) {
            final haystack = [
              entry.name,
              entry.path,
              entry.permissionString,
              entry.kind.name,
            ].join('\n').toLowerCase();
            return haystack.contains(query);
          }).toList();
    filtered.sort(_compareEntries);
    return filtered;
  }

  int get directoryCount => _entries.where((entry) => entry.isDirectory).length;
  int get fileCount => _entries.where((entry) => !entry.isDirectory).length;
  int get visibleDirectoryCount =>
      visibleEntries.where((entry) => entry.isDirectory).length;
  int get visibleFileCount =>
      visibleEntries.where((entry) => !entry.isDirectory).length;
  bool get busy => _busy;
  SftpTransfer? get transfer => _transfer;
  String? get securityKeyMessage => _securityKeyMessage;
  bool get canGoUp => _path != '/';

  void setSearchQuery(String value) {
    if (value == _searchQuery) {
      return;
    }
    _searchQuery = value;
    _safeNotify();
  }

  void clearSearch() {
    setSearchQuery('');
  }

  void setSortMode(SftpSortMode value) {
    if (value == _sortMode) {
      return;
    }
    _sortMode = value;
    _safeNotify();
  }

  Future<void> connect() async {
    _status = SftpBrowserStatus.connecting;
    _errorMessage = null;
    _securityKeyMessage = null;
    await _securityKeySubscription?.cancel();
    _securityKeySubscription = SecurityKeyInteraction.instance.messages.listen((
      message,
    ) {
      if (_status != SftpBrowserStatus.connecting) return;
      _securityKeyMessage = message;
      _safeNotify();
    });
    _safeNotify();
    try {
      final session = await repository.connect(host);
      if (_disposed) {
        unawaited(session.close());
        return;
      }
      _session = session;
      final home = await _resolveHome(session);
      await _stopSecurityKeyStatus();
      await _load(home);
    } catch (error) {
      await _stopSecurityKeyStatus();
      _fail(error);
    }
  }

  Future<void> open(SftpEntry entry) async {
    if (!entry.isNavigable || _busy) {
      return;
    }
    await _load(entry.path);
  }

  Future<void> goUp() async {
    if (!canGoUp || _busy) {
      return;
    }
    await _load(_parentOf(_path));
  }

  Future<void> navigateTo(String path) async {
    if (_busy || path == _path) {
      return;
    }
    await _load(path);
  }

  Future<void> refresh() => _load(_path);

  Future<void> makeDirectory(String name) async {
    await _mutate(() => _session!.makeDirectory(_join(_path, name)));
  }

  Future<void> rename(SftpEntry entry, String newName) async {
    await _mutate(() => _session!.rename(entry.path, _join(_path, newName)));
  }

  Future<void> delete(SftpEntry entry) async {
    await _mutate(() => _session!.delete(entry));
  }

  Future<String?> download(SftpEntry entry) async {
    final session = _session;
    if (session == null) {
      throw const AppFailure('Not connected.');
    }
    if (entry.isDirectory) {
      return _downloadDirectory(session, entry);
    }
    _transfer = SftpTransfer(
      name: entry.name,
      isUpload: false,
      done: 0,
      total: entry.size,
    );
    _safeNotify();
    try {
      final bytes = await session.read(
        entry.path,
        onProgress: (read, total) {
          _transfer = SftpTransfer(
            name: entry.name,
            isUpload: false,
            done: read,
            total: total ?? entry.size,
          );
          _safeNotify();
        },
      );
      return await fileExport.save(entry.name, bytes);
    } finally {
      _transfer = null;
      _safeNotify();
    }
  }

  Future<String?> _downloadDirectory(
    SftpSession session,
    SftpEntry entry,
  ) async {
    final archiveName = '${entry.name}.tar';
    _transfer = SftpTransfer(name: archiveName, isUpload: false, done: 0);
    _safeNotify();
    try {
      var bytesRead = 0;
      final archive = TarArchiveBuilder();
      await _addDirectoryToArchive(
        session: session,
        archive: archive,
        entry: entry,
        archivePath: _safeArchiveSegment(entry.name),
        onBytesRead: (read) {
          bytesRead += read;
          _transfer = SftpTransfer(
            name: archiveName,
            isUpload: false,
            done: bytesRead,
          );
          _safeNotify();
        },
      );
      return await fileExport.save(archiveName, archive.finish());
    } finally {
      _transfer = null;
      _safeNotify();
    }
  }

  Future<void> _addDirectoryToArchive({
    required SftpSession session,
    required TarArchiveBuilder archive,
    required SftpEntry entry,
    required String archivePath,
    required ValueChanged<int> onBytesRead,
  }) async {
    archive.addDirectory(archivePath, entry.modifiedAt);
    final children = await session.list(entry.path);
    children.sort(_compareNames);
    for (final child in children) {
      final childArchivePath =
          '$archivePath/${_safeArchiveSegment(child.name)}';
      if (child.isDirectory) {
        await _addDirectoryToArchive(
          session: session,
          archive: archive,
          entry: child,
          archivePath: childArchivePath,
          onBytesRead: onBytesRead,
        );
      } else if (!child.isSymlink) {
        var lastRead = 0;
        final bytes = await session.read(
          child.path,
          onProgress: (read, _) {
            onBytesRead(read - lastRead);
            lastRead = read;
          },
        );
        archive.addFile(childArchivePath, bytes, child.modifiedAt);
      }
    }
  }

  Future<void> uploadFile(String localPath, String name, int size) async {
    await uploadFiles([
      SftpUploadFile.local(localPath: localPath, name: name, size: size),
    ]);
  }

  Future<void> uploadFiles(List<SftpUploadFile> files) async {
    if (files.isEmpty) {
      return;
    }
    final session = _session;
    if (session == null) {
      throw const AppFailure('Not connected.');
    }
    if (_busy) {
      throw const AppFailure('A transfer is already in progress.');
    }
    _busy = true;
    _safeNotify();
    try {
      for (var index = 0; index < files.length; index += 1) {
        final file = files[index];
        final transferName = files.length == 1
            ? file.name
            : '${file.name} (${index + 1}/${files.length})';
        await _uploadFile(session, file, transferName);
      }
      await _load(_path);
    } finally {
      _busy = false;
      _transfer = null;
      _safeNotify();
    }
  }

  Future<void> _uploadFile(
    SftpSession session,
    SftpUploadFile file,
    String transferName,
  ) async {
    _transfer = SftpTransfer(
      name: transferName,
      isUpload: true,
      done: 0,
      total: file.size,
    );
    _safeNotify();
    try {
      await session.write(
        _join(_path, file.name),
        file.openRead(),
        file.size,
        onProgress: (sent) {
          _transfer = SftpTransfer(
            name: transferName,
            isUpload: true,
            done: sent,
            total: file.size,
          );
          _safeNotify();
        },
      );
    } catch (error) {
      throw AppFailure('Could not upload ${file.name}.', error);
    }
  }

  Future<void> _mutate(Future<void> Function() action) async {
    if (_session == null || _busy) {
      return;
    }
    _busy = true;
    _safeNotify();
    try {
      await action();
      await _reload(_path);
    } finally {
      _busy = false;
      _safeNotify();
    }
  }

  Future<void> _load(String path) async {
    final session = _session;
    if (session == null) {
      return;
    }
    _busy = true;
    _safeNotify();
    try {
      final entries = await session.list(path);
      if (_disposed) return;
      _path = path;
      _entries = entries;
      _status = SftpBrowserStatus.ready;
      _errorMessage = null;
    } catch (error) {
      if (_disposed) return;
      if (_status == SftpBrowserStatus.connecting) {
        _fail(error);
        return;
      }
      rethrow;
    } finally {
      _busy = false;
      _safeNotify();
    }
  }

  Future<void> _reload(String path) async {
    final session = _session;
    if (session == null) return;
    final entries = await session.list(path);
    if (_disposed) return;
    _entries = entries;
  }

  int _compareEntries(SftpEntry a, SftpEntry b) {
    if (a.isDirectory != b.isDirectory) {
      return a.isDirectory ? -1 : 1;
    }
    return switch (_sortMode) {
      SftpSortMode.name => _compareNames(a, b),
      SftpSortMode.modified => _thenByName(
        _compareNullableDates(b.modifiedAt, a.modifiedAt),
        a,
        b,
      ),
      SftpSortMode.size => _thenByName(
        _compareNullableInts(b.size, a.size),
        a,
        b,
      ),
      SftpSortMode.type => _compareTypes(a, b),
    };
  }

  int _thenByName(int compared, SftpEntry a, SftpEntry b) {
    return compared == 0 ? _compareNames(a, b) : compared;
  }

  int _compareNames(SftpEntry a, SftpEntry b) {
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  int _compareTypes(SftpEntry a, SftpEntry b) {
    final kind = a.kind.index.compareTo(b.kind.index);
    if (kind != 0) return kind;
    return _compareNames(a, b);
  }

  int _compareNullableDates(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    final compared = a.compareTo(b);
    return compared == 0 ? 0 : compared;
  }

  int _compareNullableInts(int? a, int? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    final compared = a.compareTo(b);
    return compared == 0 ? 0 : compared;
  }

  Future<String> _resolveHome(SftpSession session) async {
    try {
      final resolved = await session.resolve('.');
      return resolved.isEmpty ? '/' : resolved;
    } catch (_) {
      return '/';
    }
  }

  Future<void> _stopSecurityKeyStatus() async {
    await _securityKeySubscription?.cancel();
    _securityKeySubscription = null;
    _securityKeyMessage = null;
  }

  void _fail(Object error) {
    _status = SftpBrowserStatus.failed;
    _errorMessage = error is AppFailure ? error.toString() : '$error';
    _safeNotify();
  }

  String _parentOf(String path) {
    if (path == '/') return '/';
    final trimmed = path.endsWith('/')
        ? path.substring(0, path.length - 1)
        : path;
    final index = trimmed.lastIndexOf('/');
    if (index <= 0) return '/';
    return trimmed.substring(0, index);
  }

  String _join(String parent, String name) {
    final clean = name.trim();
    if (parent == '/') return '/$clean';
    return '$parent/$clean';
  }

  String _safeArchiveSegment(String name) {
    final safe = name
        .replaceAll('\\', '_')
        .replaceAll('/', '_')
        .trim()
        .replaceAll(RegExp(r'^\.+$'), '_');
    return safe.isEmpty ? '_' : safe;
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_securityKeySubscription?.cancel());
    _securityKeySubscription = null;
    final session = _session;
    _session = null;
    if (session != null) {
      unawaited(session.close());
    }
    super.dispose();
  }
}

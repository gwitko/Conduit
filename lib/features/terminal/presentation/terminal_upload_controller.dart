// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:conduit/features/sftp/domain/sftp_entry.dart';
import 'package:conduit/features/sftp/domain/sftp_repository.dart';
import 'package:conduit/features/sftp/domain/sftp_session.dart';
import 'package:conduit/features/sftp/domain/upload_manifest.dart';
import 'package:conduit/features/sftp/domain/upload_path.dart';
import 'package:conduit/features/sftp/presentation/sftp_browser_controller.dart'
    show SftpUploadFile;
import 'package:flutter/foundation.dart';

enum TerminalUploadPhase {
  confirming,
  connecting,
  uploading,
  success,
  failed,
  cancelled,
}

/// Progress and result for one file within an upload batch.
class TerminalUploadItem {
  TerminalUploadItem(this.file);

  final SftpUploadFile file;
  String? remotePath;
  int bytesSent = 0;
  bool done = false;

  double? get fraction {
    if (file.size <= 0) {
      return done ? 1 : null;
    }
    return (bytesSent / file.size).clamp(0.0, 1.0);
  }
}

/// Uploads one batch of picked phone files to a host over SFTP.
///
/// Owns a dedicated SFTP session for the batch (opened lazily, always closed
/// when the batch ends), builds the app-managed remote directory, avoids
/// name collisions, records every written file in the per-host upload
/// manifest, and — when the host opts into cleanup — deletes only
/// manifest-listed files older than the configured age. Nothing outside the
/// manifest is ever deleted, and directories are never removed.
class TerminalUploadController extends ChangeNotifier {
  TerminalUploadController({
    required this.host,
    required SftpRepository repository,
    required UploadManifestRepository manifest,
    DateTime Function()? now,
  }) : _repository = repository,
       _manifest = manifest,
       _now = now ?? DateTime.now;

  final SavedHost host;
  final SftpRepository _repository;
  final UploadManifestRepository _manifest;
  final DateTime Function() _now;

  TerminalUploadPhase _phase = TerminalUploadPhase.confirming;
  List<TerminalUploadItem> _items = const [];
  String? _destination;
  String? _error;
  SftpSession? _session;
  bool _cancelRequested = false;
  bool _disposed = false;

  TerminalUploadPhase get phase => _phase;
  List<TerminalUploadItem> get items => List.unmodifiable(_items);
  String? get destination => _destination;
  String? get error => _error;

  /// Remote paths of the files that finished uploading.
  List<String> get uploadedPaths => [
    for (final item in _items)
      if (item.done && item.remotePath != null) item.remotePath!,
  ];

  /// The uploaded paths, individually shell-quoted and space-separated,
  /// ready to insert into a terminal command line.
  String get quotedPathsForInsertion =>
      uploadedPaths.map(posixShellQuote).join(' ');

  void prepare(List<SftpUploadFile> files) {
    _items = [for (final file in files) TerminalUploadItem(file)];
    _phase = TerminalUploadPhase.confirming;
    _error = null;
    _notify();
  }

  /// Requests cancellation of an in-flight batch. The session is closed so
  /// the active transfer aborts promptly instead of draining.
  Future<void> cancel() async {
    if (_phase != TerminalUploadPhase.uploading &&
        _phase != TerminalUploadPhase.connecting) {
      return;
    }
    _cancelRequested = true;
    final session = _session;
    _session = null;
    if (session != null) {
      try {
        await session.close();
      } catch (_) {
        // The session may already be broken; cancellation still applies.
      }
    }
  }

  Future<void> uploadAll() async {
    if (_phase == TerminalUploadPhase.uploading ||
        _phase == TerminalUploadPhase.connecting ||
        _items.isEmpty) {
      return;
    }
    _cancelRequested = false;
    _error = null;
    _phase = TerminalUploadPhase.connecting;
    _notify();
    SftpSession? session;
    // Every file written to the server this batch, persisted to the
    // manifest in the finally block so partial batches (failure or cancel
    // mid-write) never leave unrecorded app-owned files behind.
    final newEntries = <UploadManifestEntry>[];
    try {
      session = await _repository.connect(host);
      _session = session;
      if (_cancelRequested) {
        _phase = TerminalUploadPhase.cancelled;
        _notify();
        return;
      }
      final home = await session.resolve('.');
      final directory = resolveUploadDirectory(
        home: home,
        now: _now(),
        custom: host.uploadDirectory,
      );
      _destination = directory;
      await _ensureDirectory(session, directory);
      final existing = <String>{
        for (final entry in await session.list(directory)) entry.name,
      };
      _phase = TerminalUploadPhase.uploading;
      _notify();

      for (final item in _items) {
        if (_cancelRequested) {
          break;
        }
        final name = resolveUploadCollision(
          sanitizeUploadFileName(item.file.name),
          existing,
          _now(),
        );
        existing.add(name);
        final remotePath = '$directory/$name';
        await session.write(
          remotePath,
          item.file.openRead(),
          item.file.size,
          onProgress: (bytesSent) {
            item.bytesSent = bytesSent;
            _notify();
          },
        );
        item.remotePath = remotePath;
        item.done = true;
        newEntries.add(
          UploadManifestEntry(path: remotePath, uploadedAt: _now().toUtc()),
        );
        _notify();
      }

      if (_cancelRequested) {
        _phase = TerminalUploadPhase.cancelled;
      } else {
        // Cleanup of expired earlier uploads only runs after a fully
        // successful batch; a cancelled or failed batch never deletes.
        await _cleanUpExpired(session);
        _phase = TerminalUploadPhase.success;
      }
      _notify();
    } catch (error) {
      if (_cancelRequested) {
        _phase = TerminalUploadPhase.cancelled;
      } else {
        _phase = TerminalUploadPhase.failed;
        _error = error.toString();
      }
      _notify();
    } finally {
      // Record everything that reached the server, even after a failure or
      // cancellation, so cleanup stays able to manage these files later.
      if (newEntries.isNotEmpty) {
        try {
          await _manifest.setEntries(host.id, [
            ...await _manifest.entriesFor(host.id),
            ...newEntries,
          ]);
        } catch (_) {
          // Manifest recording is best-effort; the upload result stands.
        }
      }
      final open = _session;
      _session = null;
      if (open != null) {
        try {
          await open.close();
        } catch (_) {
          // Closing a torn-down session is best-effort.
        }
      }
    }
  }

  /// Creates the target directory (and its parents) if missing. Individual
  /// mkdir failures are tolerated — components usually already exist — and
  /// the directory is verified afterwards by listing it.
  Future<void> _ensureDirectory(SftpSession session, String directory) async {
    final segments = directory.split('/').where((s) => s.isNotEmpty).toList();
    var path = '';
    for (final segment in segments) {
      path = '$path/$segment';
      try {
        await session.makeDirectory(path);
      } catch (_) {
        // Most likely "already exists"; a real failure surfaces below.
      }
    }
  }

  /// Deletes manifest-listed files older than the host's cleanup cutoff and
  /// drops them from the manifest. Only ever touches exact paths this app
  /// recorded; never directories.
  Future<void> _cleanUpExpired(SftpSession session) async {
    final days = host.uploadCleanupDays;
    if (days == null || days <= 0) {
      return;
    }
    final entries = await _manifest.entriesFor(host.id);
    if (entries.isEmpty) {
      return;
    }
    final cutoff = _now().toUtc().subtract(Duration(days: days));
    final kept = <UploadManifestEntry>[];
    for (final entry in entries) {
      if (entry.uploadedAt.isAfter(cutoff)) {
        kept.add(entry);
        continue;
      }
      try {
        await session.delete(
          SftpEntry(
            name: entry.path.split('/').last,
            path: entry.path,
            kind: SftpEntryKind.file,
          ),
        );
      } catch (_) {
        // Already gone or not deletable; either way the entry is dropped
        // so a broken file cannot be retried forever.
      }
    }
    await _manifest.setEntries(host.id, kept);
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    final open = _session;
    _session = null;
    if (open != null) {
      unawaited(open.close().catchError((_) {}));
    }
    super.dispose();
  }
}

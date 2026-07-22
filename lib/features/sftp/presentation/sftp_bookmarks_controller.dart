import 'dart:async';

import 'package:conduit/features/sftp/domain/sftp_bookmarks_repository.dart';
import 'package:flutter/foundation.dart';

/// Favorite directories for one host's SFTP browser, persisted per host.
class SftpBookmarksController extends ChangeNotifier {
  SftpBookmarksController({required this.hostId, required this.repository});

  final String hostId;
  final SftpBookmarksRepository repository;

  List<String> _bookmarks = const [];

  List<String> get bookmarks => List.unmodifiable(_bookmarks);

  bool contains(String path) => _bookmarks.contains(path);

  Future<void> load() async {
    _bookmarks = List.of(await repository.load(hostId))
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    notifyListeners();
  }

  Future<void> toggle(String path) async {
    final next = List.of(_bookmarks);
    if (!next.remove(path)) {
      next.add(path);
      next.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    }
    _bookmarks = next;
    notifyListeners();
    await repository.save(hostId, next);
  }
}

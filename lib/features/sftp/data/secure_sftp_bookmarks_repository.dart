import 'dart:convert';

import 'package:conduit/features/sftp/domain/sftp_bookmarks_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureSftpBookmarksRepository implements SftpBookmarksRepository {
  const SecureSftpBookmarksRepository(this._storage);

  static const _key = 'conduit.sftp_bookmarks.v1';

  final FlutterSecureStorage _storage;

  @override
  Future<List<String>> load(String hostId) async {
    final all = await _loadAll();
    return all[hostId] ?? const [];
  }

  @override
  Future<void> save(String hostId, List<String> paths) async {
    final all = await _loadAll();
    if (paths.isEmpty) {
      all.remove(hostId);
    } else {
      all[hostId] = paths;
    }
    await _storage.write(key: _key, value: jsonEncode(all));
  }

  Future<Map<String, List<String>>> _loadAll() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.trim().isEmpty) {
      return {};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return {};
      }
      return {
        for (final MapEntry(:key, :value) in decoded.entries)
          if (value is List) key as String: value.whereType<String>().toList(),
      };
    } catch (_) {
      return {};
    }
  }
}

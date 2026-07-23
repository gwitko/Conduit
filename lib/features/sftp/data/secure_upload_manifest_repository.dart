import 'dart:convert';

import 'package:conduit/features/sftp/domain/upload_manifest.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the per-host upload manifest as one JSON map
/// (`hostId -> [{path, at}]`) in secure storage. Corrupt payloads load as
/// an empty manifest; removing a host's last entry drops the host key.
class SecureUploadManifestRepository implements UploadManifestRepository {
  const SecureUploadManifestRepository(this._storage);

  static const _key = 'conduit.upload_manifest.v1';

  final FlutterSecureStorage _storage;

  @override
  Future<List<UploadManifestEntry>> entriesFor(String hostId) async {
    final all = await _loadAll();
    return all[hostId] ?? const [];
  }

  @override
  Future<void> setEntries(
    String hostId,
    List<UploadManifestEntry> entries,
  ) async {
    final all = await _loadAll();
    if (entries.isEmpty) {
      all.remove(hostId);
    } else {
      all[hostId] = List.of(entries);
    }
    await _storage.write(
      key: _key,
      value: jsonEncode({
        for (final MapEntry(:key, :value) in all.entries)
          key: [for (final entry in value) entry.toJson()],
      }),
    );
  }

  Future<Map<String, List<UploadManifestEntry>>> _loadAll() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.trim().isEmpty) {
      return {};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return {};
      }
      final result = <String, List<UploadManifestEntry>>{};
      for (final MapEntry(:key, :value) in decoded.entries) {
        if (key is! String || value is! List) {
          continue;
        }
        final entries = value
            .map(UploadManifestEntry.fromJson)
            .whereType<UploadManifestEntry>()
            .toList();
        if (entries.isNotEmpty) {
          result[key] = entries;
        }
      }
      return result;
    } catch (_) {
      return {};
    }
  }
}

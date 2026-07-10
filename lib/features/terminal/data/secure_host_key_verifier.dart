import 'dart:convert';

import 'package:conduit/features/terminal/domain/host_key_prompt.dart';
import 'package:conduit/features/terminal/domain/host_key_verifier.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureHostKeyVerifier implements HostKeyVerifier {
  SecureHostKeyVerifier(this._storage, this._prompt);

  static const _trustedKeysKey = 'conduit.trusted_host_keys.v1';
  static const _sha256AsciiHexFingerprintPrefix = 'MD5:53:48:41:32:35:36:3a';

  final FlutterSecureStorage _storage;
  final HostKeyPrompt _prompt;

  @override
  Future<bool> verify({
    required String host,
    required int port,
    required String type,
    required String fingerprint,
  }) async {
    final records = await loadTrustedKeys();
    final key = '$host:$port';
    final existingIndex = records.indexWhere((record) => record.key == key);
    final existing = existingIndex == -1 ? null : records[existingIndex];

    if (existing != null &&
        existing.type == type &&
        existing.fingerprint == fingerprint) {
      return true;
    }

    final decision = await _prompt.request(
      HostKeyPromptRequest(
        host: host,
        port: port,
        type: type,
        fingerprint: fingerprint,
        kind: existing == null
            ? HostKeyPromptKind.firstTrust
            : HostKeyPromptKind.mismatch,
        existing: existing,
      ),
    );

    if (decision == HostKeyDecision.reject) {
      return false;
    }

    final record = HostKeyRecord(
      host: host,
      port: port,
      type: type,
      fingerprint: fingerprint,
      trustedAt: DateTime.now(),
    );
    if (existing == null) {
      records.add(record);
    } else {
      records[existingIndex] = record;
    }
    await _save(records);
    return true;
  }

  @override
  Future<List<HostKeyRecord>> loadTrustedKeys() async {
    final raw = await _storage.read(key: _trustedKeysKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return [];
    }
    final records = decoded
        .whereType<Map<String, Object?>>()
        .map(HostKeyRecord.fromJson)
        .where(
          (record) => record.host.isNotEmpty && record.fingerprint.isNotEmpty,
        )
        .toList();
    final originalCount = records.length;
    records.removeWhere(_isAsciiHexSha256Fingerprint);
    if (records.length != originalCount) {
      await _save(records);
    }
    return records;
  }

  @override
  Future<void> saveTrustedKeys(List<HostKeyRecord> records) {
    final byKey = <String, HostKeyRecord>{};
    for (final record in records) {
      if (record.host.isNotEmpty && record.fingerprint.isNotEmpty) {
        byKey[record.key] = record;
      }
    }
    return _save(byKey.values.toList(growable: false));
  }

  @override
  Future<void> removeTrustedKey(String host, int port) async {
    final key = '$host:$port';
    final records = await loadTrustedKeys();
    records.removeWhere((record) => record.key == key);
    await _save(records);
  }

  Future<void> _save(List<HostKeyRecord> records) {
    return _storage.write(
      key: _trustedKeysKey,
      value: jsonEncode(records.map((record) => record.toJson()).toList()),
    );
  }

  bool _isAsciiHexSha256Fingerprint(HostKeyRecord record) {
    return record.fingerprint.toLowerCase().startsWith(
      _sha256AsciiHexFingerprintPrefix.toLowerCase(),
    );
  }
}

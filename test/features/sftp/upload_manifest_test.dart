import 'package:conduit/features/sftp/data/secure_upload_manifest_repository.dart';
import 'package:conduit/features/sftp/domain/upload_manifest.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

void main() {
  group('SecureUploadManifestRepository', () {
    final entryA = UploadManifestEntry(
      path: '/home/u/.conduit/uploads/2026-07-04/a.png',
      uploadedAt: DateTime.utc(2026, 7, 4, 10),
    );
    final entryB = UploadManifestEntry(
      path: '/home/u/.conduit/uploads/2026-07-04/b.pdf',
      uploadedAt: DateTime.utc(2026, 7, 4, 11),
    );

    test('round-trips entries per host', () async {
      final storage = InMemorySecureStorage();
      final repository = SecureUploadManifestRepository(storage);

      await repository.setEntries('host-1', [entryA]);
      await repository.setEntries('host-2', [entryB]);

      expect(await repository.entriesFor('host-1'), [entryA]);
      expect(await repository.entriesFor('host-2'), [entryB]);
      expect(await repository.entriesFor('host-3'), isEmpty);
    });

    test('drops a host key when its entries empty out', () async {
      final storage = InMemorySecureStorage();
      final repository = SecureUploadManifestRepository(storage);

      await repository.setEntries('host-1', [entryA]);
      await repository.setEntries('host-1', []);

      expect(await repository.entriesFor('host-1'), isEmpty);
      final raw = await storage.read(key: 'conduit.upload_manifest.v1');
      expect(raw, isNot(contains('host-1')));
    });

    test('loads corrupt payloads as an empty manifest', () async {
      final storage = InMemorySecureStorage();
      await storage.write(
        key: 'conduit.upload_manifest.v1',
        value: 'not-json{{{',
      );
      final repository = SecureUploadManifestRepository(storage);

      expect(await repository.entriesFor('host-1'), isEmpty);
    });

    test('skips malformed entries while keeping valid ones', () async {
      final storage = InMemorySecureStorage();
      await storage.write(
        key: 'conduit.upload_manifest.v1',
        value:
            '{"host-1":[{"path":"/ok","at":1000},{"path":"","at":2},'
            '{"nope":true},42]}',
      );
      final repository = SecureUploadManifestRepository(storage);

      final entries = await repository.entriesFor('host-1');
      expect(entries, hasLength(1));
      expect(entries.single.path, '/ok');
    });
  });
}

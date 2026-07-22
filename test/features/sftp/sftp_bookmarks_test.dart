import 'package:conduit/features/sftp/data/secure_sftp_bookmarks_repository.dart';
import 'package:conduit/features/sftp/presentation/sftp_bookmarks_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

void main() {
  group('SecureSftpBookmarksRepository', () {
    test('round-trips bookmarks per host', () async {
      final repository = SecureSftpBookmarksRepository(InMemorySecureStorage());

      await repository.save('host-a', ['/var/www', '/etc']);
      await repository.save('host-b', ['/home/user']);

      expect(await repository.load('host-a'), ['/var/www', '/etc']);
      expect(await repository.load('host-b'), ['/home/user']);
      expect(await repository.load('host-c'), isEmpty);
    });

    test('saving an empty list clears the host entry', () async {
      final repository = SecureSftpBookmarksRepository(InMemorySecureStorage());

      await repository.save('host-a', ['/etc']);
      await repository.save('host-a', []);

      expect(await repository.load('host-a'), isEmpty);
    });

    test('corrupt stored payload loads as no bookmarks', () async {
      final storage = InMemorySecureStorage();
      await storage.write(key: 'conduit.sftp_bookmarks.v1', value: '{oops');
      final repository = SecureSftpBookmarksRepository(storage);

      expect(await repository.load('host-a'), isEmpty);
    });
  });

  group('SftpBookmarksController', () {
    test('toggle adds sorted, then removes, and persists', () async {
      final repository = InMemorySftpBookmarks();
      final controller = SftpBookmarksController(
        hostId: 'host-a',
        repository: repository,
      );

      await controller.toggle('/var/www');
      await controller.toggle('/etc');
      expect(controller.bookmarks, ['/etc', '/var/www']);
      expect(controller.contains('/etc'), isTrue);
      expect(repository.stored['host-a'], ['/etc', '/var/www']);

      await controller.toggle('/etc');
      expect(controller.bookmarks, ['/var/www']);
      expect(controller.contains('/etc'), isFalse);
    });

    test('load reads persisted bookmarks for its host only', () async {
      final repository = InMemorySftpBookmarks();
      await repository.save('host-a', ['/b', '/a']);
      await repository.save('host-b', ['/other']);
      final controller = SftpBookmarksController(
        hostId: 'host-a',
        repository: repository,
      );

      await controller.load();

      expect(controller.bookmarks, ['/a', '/b']);
    });
  });
}

import 'package:conduit/features/local_shell/local_shell_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('defaultRootfsManifest', () {
    final manifest = defaultRootfsManifest();

    test('points at a verified https archive', () {
      expect(manifest.archiveUrl.scheme, 'https');
      expect(manifest.archiveUrl.host, 'github.com');
      expect(manifest.archiveUrl.path, contains('.tar.xz'));
    });

    test('carries the verified checksum and size', () {
      expect(manifest.sha256, hasLength(64));
      expect(
        manifest.sha256,
        'b7e4cfb1414a281f90bfd39a503f72f38e03c31b356927972f797988fb48b5b1',
      );
      expect(manifest.downloadSizeBytes, 149200240);
    });

    test('targets the Arch Linux ARM keyring and mirror', () {
      expect(manifest.keyringName, 'archlinuxarm');
      expect(manifest.pacmanMirror, contains('archlinuxarm.org'));
    });
  });
}

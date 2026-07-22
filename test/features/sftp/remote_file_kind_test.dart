import 'package:conduit/features/sftp/domain/remote_file_kind.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('remoteFileKindForPath', () {
    test('classifies images, pdf, and html by extension', () {
      expect(remoteFileKindForPath('/a/photo.PNG'), RemoteFileKind.image);
      expect(remoteFileKindForPath('/a/photo.jpeg'), RemoteFileKind.image);
      expect(remoteFileKindForPath('/a/doc.pdf'), RemoteFileKind.pdf);
      expect(remoteFileKindForPath('/srv/index.html'), RemoteFileKind.html);
      expect(remoteFileKindForPath('/srv/index.htm'), RemoteFileKind.html);
    });

    test('everything else is text', () {
      expect(remoteFileKindForPath('/a/main.dart'), RemoteFileKind.text);
      expect(remoteFileKindForPath('/etc/hosts'), RemoteFileKind.text);
      expect(remoteFileKindForPath('/a/.bashrc'), RemoteFileKind.text);
    });
  });

  group('remoteFileName and extension', () {
    test('takes the last path segment', () {
      expect(remoteFileName('/a/b/c.txt'), 'c.txt');
      expect(remoteFileName('c.txt'), 'c.txt');
      expect(remoteFileName('/a/b/'), 'b');
    });

    test('dotfiles have no extension', () {
      expect(remoteFileExtension('/home/.bashrc'), '');
      expect(remoteFileExtension('/home/a.tar.gz'), 'gz');
      expect(remoteFileExtension('/home/name.'), '');
    });
  });

  group('remoteFileLooksTextual', () {
    test('NUL byte marks binary; plain text passes', () {
      expect(remoteFileLooksTextual('hello\nworld'.codeUnits), isTrue);
      expect(remoteFileLooksTextual([0x68, 0x00, 0x69]), isFalse);
      expect(remoteFileLooksTextual(const []), isTrue);
    });
  });
}

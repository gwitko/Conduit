import 'package:conduit/features/sftp/domain/upload_path.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveUploadDirectory', () {
    final now = DateTime(2026, 7, 4);

    test('defaults to a dated folder under ~/.conduit/uploads', () {
      expect(
        resolveUploadDirectory(home: '/home/user', now: now),
        '/home/user/.conduit/uploads/2026-07-04',
      );
    });

    test('trims a trailing slash from home', () {
      expect(
        resolveUploadDirectory(home: '/home/user/', now: now),
        '/home/user/.conduit/uploads/2026-07-04',
      );
    });

    test('accepts absolute, tilde-relative, and home-relative overrides', () {
      expect(
        resolveUploadDirectory(home: '/h', now: now, custom: '/srv/drop/'),
        '/srv/drop',
      );
      expect(
        resolveUploadDirectory(home: '/h', now: now, custom: '~/incoming'),
        '/h/incoming',
      );
      expect(
        resolveUploadDirectory(home: '/h', now: now, custom: 'incoming'),
        '/h/incoming',
      );
      expect(resolveUploadDirectory(home: '/h', now: now, custom: '~'), '/h');
    });

    test('treats blank overrides as the default', () {
      expect(
        resolveUploadDirectory(home: '/h', now: now, custom: '   '),
        '/h/.conduit/uploads/2026-07-04',
      );
    });
  });

  group('sanitizeUploadFileName', () {
    test('keeps ordinary names, spaces, and unicode intact', () {
      expect(
        sanitizeUploadFileName('Screenshot 2026.png'),
        'Screenshot 2026.png',
      );
      expect(sanitizeUploadFileName('фото ☕.jpg'), 'фото ☕.jpg');
    });

    test('strips directory components from path-like names', () {
      expect(sanitizeUploadFileName('../../etc/passwd'), 'passwd');
      expect(sanitizeUploadFileName(r'C:\Users\me\doc.pdf'), 'doc.pdf');
    });

    test('removes control characters', () {
      expect(sanitizeUploadFileName('bad\x00name\x1f.txt'), 'badname.txt');
    });

    test('falls back for empty or dot names', () {
      expect(sanitizeUploadFileName(''), 'file');
      expect(sanitizeUploadFileName('..'), 'file');
      expect(sanitizeUploadFileName('  '), 'file');
    });
  });

  group('resolveUploadCollision', () {
    final now = DateTime(2026, 7, 4, 14, 35, 2);

    test('keeps a non-colliding name', () {
      expect(resolveUploadCollision('a.jpg', {'b.jpg'}, now), 'a.jpg');
    });

    test('adds a timestamp before the extension on collision', () {
      expect(
        resolveUploadCollision('photo.jpg', {'photo.jpg'}, now),
        'photo-143502.jpg',
      );
    });

    test('adds a counter when the timestamped name also collides', () {
      expect(
        resolveUploadCollision('photo.jpg', {
          'photo.jpg',
          'photo-143502.jpg',
        }, now),
        'photo-143502-2.jpg',
      );
    });

    test('handles extensionless and dotfile names', () {
      expect(resolveUploadCollision('notes', {'notes'}, now), 'notes-143502');
      expect(
        resolveUploadCollision('.envrc', {'.envrc'}, now),
        '.envrc-143502',
      );
    });
  });

  group('posixShellQuote', () {
    test('passes through unambiguously safe values', () {
      expect(posixShellQuote('/home/user/file.txt'), '/home/user/file.txt');
      expect(posixShellQuote('a-b_c.1/d'), 'a-b_c.1/d');
    });

    test('quotes spaces, globs, and metacharacters', () {
      expect(posixShellQuote('my file.txt'), "'my file.txt'");
      expect(posixShellQuote(r'a$(rm -rf).txt'), r"'a$(rm -rf).txt'");
      expect(posixShellQuote('a*b?.txt'), "'a*b?.txt'");
      expect(posixShellQuote('semi;colon'), "'semi;colon'");
      expect(posixShellQuote('(parens).pdf'), "'(parens).pdf'");
    });

    test('escapes embedded single quotes', () {
      expect(posixShellQuote("it's here.txt"), r"'it'\''s here.txt'");
    });

    test('quotes newlines and leading dashes', () {
      expect(posixShellQuote('line\nbreak'), "'line\nbreak'");
      expect(posixShellQuote('-rf'), "'-rf'");
    });

    test('quotes the empty string', () {
      expect(posixShellQuote(''), "''");
    });
  });
}

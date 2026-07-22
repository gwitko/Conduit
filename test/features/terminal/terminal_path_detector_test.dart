import 'package:conduit/features/terminal/domain/terminal_path_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('terminalPathAt', () {
    test('finds an absolute path under the tapped column', () {
      const line = 'error in /etc/nginx/nginx.conf on line 4';
      expect(
        terminalPathAt(line, line.indexOf('nginx.conf')),
        '/etc/nginx/nginx.conf',
      );
      expect(
        terminalPathAt(line, line.indexOf('/etc')),
        '/etc/nginx/nginx.conf',
      );
    });

    test('returns null when tapping outside the path', () {
      const line = 'error in /etc/nginx/nginx.conf on line 4';
      expect(terminalPathAt(line, line.indexOf('error')), isNull);
      expect(terminalPathAt(line, line.indexOf(' on')), isNull);
    });

    test('strips grep line and column suffixes', () {
      const line = 'lib/main.dart:42:7: Warning: unused import';
      expect(terminalPathAt(line, 3), 'lib/main.dart');
    });

    test('strips sentence punctuation and quotes stay excluded', () {
      const line = 'see /var/log/syslog. for details';
      expect(terminalPathAt(line, 6), '/var/log/syslog');
    });

    test('accepts home-relative and dot-relative paths', () {
      const home = 'saved to ~/notes/todo.md just now';
      expect(terminalPathAt(home, home.indexOf('todo')), '~/notes/todo.md');
      const dot = 'run ./scripts/build.sh first';
      expect(terminalPathAt(dot, dot.indexOf('build')), './scripts/build.sh');
    });

    test('rejects URLs, plain words, and timestamps', () {
      const url = 'open https://example.com/a/b now';
      expect(terminalPathAt(url, url.indexOf('example')), isNull);
      expect(terminalPathAt('just some words here', 6), isNull);
      const time = 'at 12:34:56 today';
      expect(terminalPathAt(time, 4), isNull);
    });

    test('handles out-of-range columns and blank lines', () {
      expect(terminalPathAt('', 0), isNull);
      expect(terminalPathAt('/etc/hosts', -1), isNull);
      expect(terminalPathAt('/etc/hosts', 999), isNull);
    });

    test('extracts the value of --flag=/path arguments', () {
      const line = 'nginx --conf=/etc/nginx/nginx.conf -g daemon';
      expect(
        terminalPathAt(line, line.indexOf('/etc')),
        '/etc/nginx/nginx.conf',
      );
    });

    test('trims a trailing slash from directory paths', () {
      const line = 'ls /opt/data/ done';
      expect(terminalPathAt(line, 5), '/opt/data');
    });
  });
}

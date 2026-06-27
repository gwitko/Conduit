import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled local-shell notices are packaged as assets', () async {
    const assets = [
      'third_party/licenses/GPL-2.0-only.txt',
      'third_party/licenses/GPL-3.0-or-later.txt',
      'third_party/licenses/LGPL-2.1-or-later.txt',
      'third_party/licenses/LGPL-3.0-or-later.txt',
      'third_party/notices/xz.txt',
      'third_party/notices/libandroid-shmem.txt',
      'third_party/notices/libandroid-selinux.txt',
      'third_party/notices/libandroid-glob.txt',
      'third_party/notices/pcre2.txt',
    ];

    for (final asset in assets) {
      final text = await rootBundle.loadString(asset);
      expect(text.trim(), isNotEmpty, reason: asset);
    }
  });
}

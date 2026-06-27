import 'package:conduit/features/local_shell/domain/first_boot_script.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const generator = FirstBootScript();
  const config = FirstBootConfig(
    pacmanMirror: r'http://mirror.archlinuxarm.org/$arch/$repo',
    keyringName: 'archlinuxarm',
    doneMarkerPath: '/var/lib/.conduit-firstboot-done',
  );

  group('FirstBootScript', () {
    final script = generator.generate(config);

    test('configures DNS for every nameserver', () {
      expect(script, contains('> /etc/resolv.conf'));
      expect(script, contains('nameserver 1.1.1.1'));
      expect(script, contains('nameserver 8.8.8.8'));
    });

    test('pins the pacman mirror', () {
      expect(
        script,
        contains(
          r"echo 'Server = http://mirror.archlinuxarm.org/$arch/$repo' > "
          '/etc/pacman.d/mirrorlist',
        ),
      );
    });

    test('generates locales', () {
      expect(script, contains('locale-gen'));
      expect(script, contains('/etc/locale.gen'));
    });

    test('seeds entropy then initialises the keyring', () {
      final entropyIndex = script.indexOf('/dev/urandom');
      final initIndex = script.indexOf('pacman-key --init');
      final populateIndex = script.indexOf(
        'pacman-key --populate archlinuxarm',
      );
      expect(entropyIndex, greaterThanOrEqualTo(0));
      expect(initIndex, greaterThan(entropyIndex));
      expect(populateIndex, greaterThan(initIndex));
    });

    test('is idempotent via a completion marker', () {
      expect(script, contains('if [ -f "/var/lib/.conduit-firstboot-done" ]'));
      expect(script, contains('touch "/var/lib/.conduit-firstboot-done"'));
    });

    test('installs a one-time welcome hint pointing at pacman -Syu', () {
      expect(script, contains('/etc/profile.d/conduit-welcome.sh'));
      expect(script, contains('pacman -Syu'));
    });
  });
}

import 'package:conduit/features/local_shell/domain/local_shell_distro.dart';
import 'package:conduit/features/local_shell/domain/rootfs_manifest.dart';

const String defaultLocalShellDistroId = 'archlinux';

const String _rootfsBaseUrl =
    'https://github.com/phyluke/conduit-rootfs/releases/download/rootfs-pd-v4.37.0';

const List<String> _pacmanLocaleSetup = [
  "echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen",
  "echo 'C.UTF-8 UTF-8' >> /etc/locale.gen",
  'locale-gen',
  "echo 'LANG=en_US.UTF-8' > /etc/locale.conf",
];

const List<String> _debianLocaleSetup = [
  r"sed -i -E 's/#[[:space:]]?(en_US.UTF-8[[:space:]]+UTF-8)/\1/g' "
      '/etc/locale.gen',
  'DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales',
];

const List<String> _keyringEntropySeed = [
  'head -c 4096 /dev/urandom > /root/.rnd 2>/dev/null || true',
];

List<LocalShellDistro> defaultLocalShellDistros() => [
  LocalShellDistro(
    id: 'archlinux',
    name: 'Arch Linux',
    updateCommand: 'pacman -Syu',
    setupCommands: [
      'mkdir -p /etc/pacman.d',
      r"echo 'Server = http://mirror.archlinuxarm.org/$arch/$repo'"
          ' > /etc/pacman.d/mirrorlist',
      ..._pacmanLocaleSetup,
      ..._keyringEntropySeed,
      'pacman-key --init',
      'pacman-key --populate archlinuxarm',
    ],
    manifest: RootfsManifest(
      version: 'archlinux-aarch64-pd-v4.37.0',
      archiveUrl: Uri.parse(
        '$_rootfsBaseUrl/archlinux-aarch64-pd-v4.37.0.tar.xz',
      ),
      sha256:
          '718151cc4adad701223c689a7e4690cb7710b7b16e9b23617b671856ff04d563',
      downloadSizeBytes: 176379228,
    ),
  ),
  LocalShellDistro(
    id: 'debian',
    name: 'Debian',
    updateCommand: 'apt update && apt upgrade',
    setupCommands: _debianLocaleSetup,
    manifest: RootfsManifest(
      version: 'debian-trixie-aarch64-pd-v4.37.0',
      archiveUrl: Uri.parse(
        '$_rootfsBaseUrl/'
        'debian-trixie-aarch64-pd-v4.37.0.tar.xz',
      ),
      sha256:
          '9bd3b19ff7cd300c7c7bf33124b726eb199f4bab9a3b1472f34749c6d12c9195',
      downloadSizeBytes: 35401288,
    ),
  ),
  LocalShellDistro(
    id: 'ubuntu',
    name: 'Ubuntu',
    updateCommand: 'apt update && apt upgrade',
    setupCommands: _debianLocaleSetup,
    manifest: RootfsManifest(
      version: 'ubuntu-questing-aarch64-pd-v4.37.0',
      archiveUrl: Uri.parse(
        '$_rootfsBaseUrl/'
        'ubuntu-questing-aarch64-pd-v4.37.0.tar.xz',
      ),
      sha256:
          '37e61ce5fd8593a7d10c4e72ebe611adb7e795f7492e4c0bf3a950441c984161',
      downloadSizeBytes: 57561884,
    ),
  ),
  LocalShellDistro(
    id: 'alpine',
    name: 'Alpine Linux',
    updateCommand: 'apk update && apk upgrade',
    loginCommand: ['/bin/sh', '-l'],
    manifest: RootfsManifest(
      version: 'alpine-aarch64-pd-v4.37.0',
      archiveUrl: Uri.parse('$_rootfsBaseUrl/alpine-aarch64-pd-v4.37.0.tar.xz'),
      sha256:
          '2bdfb03eae53e6163695f4cd3b86e67ddca78466c879a140e069b1263150599b',
      downloadSizeBytes: 3489164,
    ),
  ),
  LocalShellDistro(
    id: 'rocky',
    name: 'Rocky Linux',
    updateCommand: 'dnf upgrade',
    manifest: RootfsManifest(
      version: 'rocky-aarch64-pd-v4.37.0',
      archiveUrl: Uri.parse('$_rootfsBaseUrl/rocky-aarch64-pd-v4.37.0.tar.xz'),
      sha256:
          '0282a82a75e0b17aa0f72622847ee0bfda85fa84bb6cf49bc72c5515816c47f0',
      downloadSizeBytes: 52225336,
    ),
  ),
  LocalShellDistro(
    id: 'opensuse',
    name: 'openSUSE Leap',
    updateCommand: 'zypper refresh && zypper update',
    setupCommands: const ['zypper al filesystem'],
    manifest: RootfsManifest(
      version: 'opensuse-aarch64-pd-v4.37.0',
      archiveUrl: Uri.parse(
        '$_rootfsBaseUrl/opensuse-aarch64-pd-v4.37.0.tar.xz',
      ),
      sha256:
          '812bbed638f43b81846520bf4283c18da08e19f14714e56fffdc9ccad3c65d7a',
      downloadSizeBytes: 47451080,
    ),
  ),
  LocalShellDistro(
    id: 'void',
    name: 'Void Linux',
    updateCommand: 'xbps-install -Su',
    setupCommands: const [
      'usermod --shell /bin/bash root',
      'update-ca-certificates --fresh',
    ],
    manifest: RootfsManifest(
      version: 'void-aarch64-pd-v4.29.0',
      archiveUrl: Uri.parse('$_rootfsBaseUrl/void-aarch64-pd-v4.29.0.tar.xz'),
      sha256:
          '7a7c449b3efe504749e40f556d13812010bccc930a820a56973a0f5fc2f16997',
      downloadSizeBytes: 51095528,
    ),
  ),
  LocalShellDistro(
    id: 'manjaro',
    name: 'Manjaro',
    updateCommand: 'pacman -Syu',
    setupCommands: [
      ..._pacmanLocaleSetup,
      ..._keyringEntropySeed,
      'pacman-key --init',
      'pacman-key --populate',
    ],
    manifest: RootfsManifest(
      version: 'manjaro-aarch64-pd-v4.37.0',
      archiveUrl: Uri.parse(
        '$_rootfsBaseUrl/manjaro-aarch64-pd-v4.37.0.tar.xz',
      ),
      sha256:
          '90fd86130d440b6d6ed6408b21306189eb41fe07d0026aab836ae203a1c419a4',
      downloadSizeBytes: 140621696,
    ),
  ),
];

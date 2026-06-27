import 'package:conduit/features/local_shell/domain/rootfs_manifest.dart';

RootfsManifest defaultRootfsManifest() => RootfsManifest(
  version: 'archlinux-aarch64-pd-v4.22.1',
  archiveUrl: Uri.parse(
    'https://github.com/termux/proot-distro/releases/download/'
    'v4.22.1/archlinux-aarch64-pd-v4.22.1.tar.xz',
  ),
  sha256: 'b7e4cfb1414a281f90bfd39a503f72f38e03c31b356927972f797988fb48b5b1',
  downloadSizeBytes: 149200240,
  pacmanMirror: r'http://mirror.archlinuxarm.org/$arch/$repo',
);

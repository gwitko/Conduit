import 'package:path/path.dart' as p;

class LocalShellPaths {
  const LocalShellPaths({
    required this.nativeLibraryDir,
    required this.dataDir,
  });

  final String nativeLibraryDir;

  final String dataDir;

  String get prootBinary => p.join(nativeLibraryDir, 'libproot.so');
  String get loaderPath => p.join(nativeLibraryDir, 'libproot_loader.so');
  String get busyboxBinary => p.join(nativeLibraryDir, 'libbusyboxbin.so');

  String get busyboxLink => p.join(installRoot, 'busybox');

  String get tarBinary => p.join(nativeLibraryDir, 'libtarbin.so');

  String get xzBinary => p.join(nativeLibraryDir, 'libxzbin.so');

  String get installRoot => p.join(dataDir, 'archlinux');
  String get rootfsDir => p.join(installRoot, 'rootfs');
  String get tmpDir => p.join(installRoot, 'tmp');
  String get downloadPath => p.join(installRoot, 'rootfs.tar.xz');
  String get versionFile => p.join(installRoot, '.version');

  String get firstBootMarker => '/var/lib/.conduit-firstboot-done';

  String get firstBootMarkerHostPath =>
      p.join(rootfsDir, 'var', 'lib', '.conduit-firstboot-done');
}

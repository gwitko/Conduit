import 'package:path/path.dart' as p;

class LocalShellPaths {
  const LocalShellPaths({
    required this.nativeLibraryDir,
    required this.dataDir,
    this.sharedStorageFeatureEnabled = false,
    this.sharedStorageDir = '',
    this.sharedStorageAccessGranted = false,
  });

  final String nativeLibraryDir;

  final String dataDir;
  final bool sharedStorageFeatureEnabled;
  final String sharedStorageDir;
  final bool sharedStorageAccessGranted;

  static const androidSharedMountPoint = '/mnt/android';

  String get prootBinary => p.join(nativeLibraryDir, 'libproot.so');
  String get loaderPath => p.join(nativeLibraryDir, 'libproot_loader.so');
  String get busyboxBinary => p.join(nativeLibraryDir, 'libbusyboxbin.so');

  String get busyboxLink => p.join(installRoot, 'busybox');

  String get tarBinary => p.join(nativeLibraryDir, 'libtarbin.so');

  String get xzBinary => p.join(nativeLibraryDir, 'libxzbin.so');

  String get installRoot => p.join(dataDir, 'archlinux');
  String get rootfsDir => p.join(installRoot, 'rootfs');
  String get androidSharedMountHostPath => p.join(rootfsDir, 'mnt', 'android');
  bool get canMountSharedStorage =>
      sharedStorageFeatureEnabled &&
      sharedStorageAccessGranted &&
      sharedStorageDir.trim().isNotEmpty;
  String get tmpDir => p.join(installRoot, 'tmp');
  String get downloadPath => p.join(installRoot, 'rootfs.tar.xz');
  String get versionFile => p.join(installRoot, '.version');

  String get firstBootMarker => '/var/lib/.conduit-firstboot-done';

  String get firstBootMarkerHostPath =>
      p.join(rootfsDir, 'var', 'lib', '.conduit-firstboot-done');
}

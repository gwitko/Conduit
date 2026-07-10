import 'dart:io';

import 'package:flutter/services.dart';

class LocalShellEnvironment {
  const LocalShellEnvironment({
    required this.nativeLibraryDir,
    required this.filesDir,
    required this.sharedStorageFeatureEnabled,
    required this.sharedStorageDir,
    required this.sharedStorageAccessGranted,
    required this.supportedAbis,
  });

  final String nativeLibraryDir;
  final String filesDir;
  final bool sharedStorageFeatureEnabled;
  final String sharedStorageDir;
  final bool sharedStorageAccessGranted;
  final List<String> supportedAbis;

  bool get isArm64 => supportedAbis.contains('arm64-v8a');
  bool get isUsable =>
      isArm64 && nativeLibraryDir.isNotEmpty && filesDir.isNotEmpty;
}

class LocalShellPlatform {
  const LocalShellPlatform([
    this._channel = const MethodChannel('conduit/local_shell'),
  ]);

  final MethodChannel _channel;

  Future<LocalShellEnvironment?> load() async {
    if (!Platform.isAndroid) return null;
    final result = await _channel.invokeMapMethod<String, Object?>(
      'environment',
    );
    if (result == null) return null;
    final abis =
        (result['supportedAbis'] as List?)?.whereType<String>().toList(
          growable: false,
        ) ??
        const <String>[];
    return LocalShellEnvironment(
      nativeLibraryDir: (result['nativeLibraryDir'] as String?) ?? '',
      filesDir: (result['filesDir'] as String?) ?? '',
      sharedStorageFeatureEnabled:
          result['sharedStorageFeatureEnabled'] as bool? ?? false,
      sharedStorageDir: (result['sharedStorageDir'] as String?) ?? '',
      sharedStorageAccessGranted:
          result['sharedStorageAccessGranted'] as bool? ?? false,
      supportedAbis: abis,
    );
  }

  Future<bool> requestSharedStorageAccess() async {
    if (!Platform.isAndroid) return false;
    return await _channel.invokeMethod<bool>('requestSharedStorageAccess') ??
        false;
  }
}

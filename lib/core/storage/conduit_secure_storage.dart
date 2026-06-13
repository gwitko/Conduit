import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

FlutterSecureStorage createConduitSecureStorage() {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
    return LinuxFallbackSecureStorage(const FlutterSecureStorage());
  }
  return const FlutterSecureStorage();
}

@visibleForTesting
class LinuxFallbackSecureStorage extends FlutterSecureStorage {
  LinuxFallbackSecureStorage(this._primary, {File? fallbackFile})
    : _fallbackFile = fallbackFile ?? _defaultFallbackFile();

  final FlutterSecureStorage _primary;
  final File _fallbackFile;
  bool _useFallback = false;

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (_useFallback) {
      await _writeFallback(key, value);
      return;
    }

    try {
      await _primary.write(
        key: key,
        value: value,
        iOptions: iOptions,
        aOptions: aOptions,
        lOptions: lOptions,
        webOptions: webOptions,
        mOptions: mOptions,
        wOptions: wOptions,
      );
    } on PlatformException catch (error) {
      if (!_isLockedKeyring(error)) rethrow;
      _useFallback = true;
      await _writeFallback(key, value);
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (_useFallback) {
      return (await _readFallback())[key];
    }

    try {
      return await _primary.read(
        key: key,
        iOptions: iOptions,
        aOptions: aOptions,
        lOptions: lOptions,
        webOptions: webOptions,
        mOptions: mOptions,
        wOptions: wOptions,
      );
    } on PlatformException catch (error) {
      if (!_isLockedKeyring(error)) rethrow;
      _useFallback = true;
      return (await _readFallback())[key];
    }
  }

  @override
  Future<bool> containsKey({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (_useFallback) {
      return (await _readFallback()).containsKey(key);
    }

    try {
      return await _primary.containsKey(
        key: key,
        iOptions: iOptions,
        aOptions: aOptions,
        lOptions: lOptions,
        webOptions: webOptions,
        mOptions: mOptions,
        wOptions: wOptions,
      );
    } on PlatformException catch (error) {
      if (!_isLockedKeyring(error)) rethrow;
      _useFallback = true;
      return (await _readFallback()).containsKey(key);
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (_useFallback) {
      await _writeFallback(key, null);
      return;
    }

    try {
      await _primary.delete(
        key: key,
        iOptions: iOptions,
        aOptions: aOptions,
        lOptions: lOptions,
        webOptions: webOptions,
        mOptions: mOptions,
        wOptions: wOptions,
      );
    } on PlatformException catch (error) {
      if (!_isLockedKeyring(error)) rethrow;
      _useFallback = true;
      await _writeFallback(key, null);
    }
  }

  @override
  Future<Map<String, String>> readAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (_useFallback) {
      return _readFallback();
    }

    try {
      return await _primary.readAll(
        iOptions: iOptions,
        aOptions: aOptions,
        lOptions: lOptions,
        webOptions: webOptions,
        mOptions: mOptions,
        wOptions: wOptions,
      );
    } on PlatformException catch (error) {
      if (!_isLockedKeyring(error)) rethrow;
      _useFallback = true;
      return _readFallback();
    }
  }

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (_useFallback) {
      await _saveFallback({});
      return;
    }

    try {
      await _primary.deleteAll(
        iOptions: iOptions,
        aOptions: aOptions,
        lOptions: lOptions,
        webOptions: webOptions,
        mOptions: mOptions,
        wOptions: wOptions,
      );
    } on PlatformException catch (error) {
      if (!_isLockedKeyring(error)) rethrow;
      _useFallback = true;
      await _saveFallback({});
    }
  }

  Future<void> _writeFallback(String key, String? value) async {
    final values = await _readFallback();
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
    await _saveFallback(values);
  }

  Future<Map<String, String>> _readFallback() async {
    if (!await _fallbackFile.exists()) {
      return {};
    }

    final decoded = jsonDecode(await _fallbackFile.readAsString());
    if (decoded is! Map) {
      return {};
    }

    return decoded.map((key, value) => MapEntry('$key', '$value'));
  }

  Future<void> _saveFallback(Map<String, String> values) async {
    await _fallbackFile.parent.create(recursive: true);
    await _fallbackFile.writeAsString(jsonEncode(values));
  }

  bool _isLockedKeyring(PlatformException error) {
    return error.code == 'KeyringLocked';
  }

  static File _defaultFallbackFile() {
    final configHome = Platform.environment['XDG_CONFIG_HOME'];
    final home = Platform.environment['HOME'];
    final basePath = configHome != null && configHome.isNotEmpty
        ? configHome
        : home == null || home.isEmpty
        ? '.config'
        : '$home/.config';
    return File('$basePath/conduit/desktop_secure_storage.json');
  }
}

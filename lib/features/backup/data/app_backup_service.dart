// ignore_for_file: prefer_initializing_formals

import 'dart:convert';
import 'dart:math';

import 'package:conduit/core/theme/app_palette.dart';
import 'package:conduit/core/theme/terminal_appearance.dart';
import 'package:conduit/core/theme/theme_controller.dart';
import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:conduit/features/hosts/domain/saved_hosts_repository.dart';
import 'package:conduit/features/hosts/presentation/hosts_controller.dart';
import 'package:conduit/features/snippets/domain/terminal_snippet.dart';
import 'package:conduit/features/terminal/domain/host_key_verifier.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:pinenacl/x25519.dart';

class AppBackupService {
  AppBackupService({
    required HostsController hostsController,
    required ThemeController themeController,
    required HostKeyVerifier hostKeyVerifier,
    AppBackupCrypto crypto = const AppBackupCrypto(),
    DateTime Function()? now,
  }) : _hostsController = hostsController,
       _themeController = themeController,
       _hostKeyVerifier = hostKeyVerifier,
       _crypto = crypto,
       _now = now ?? DateTime.now;

  static const fileExtension = 'conduit-backup.json';

  final HostsController _hostsController;
  final ThemeController _themeController;
  final HostKeyVerifier _hostKeyVerifier;
  final AppBackupCrypto _crypto;
  final DateTime Function() _now;

  Future<Uint8List> exportBackup({
    required bool includeSecrets,
    String? password,
  }) async {
    final payload = await _payload(includeSecrets: includeSecrets);
    if (!includeSecrets) {
      return _encodeJson({
        'format': 'conduit.backup',
        'version': 1,
        'encrypted': false,
        'createdAt': _now().toUtc().toIso8601String(),
        'payload': payload,
      });
    }

    final secret = password ?? '';
    final validation = AppBackupPasswordPolicy.validate(secret);
    if (validation != null) {
      throw AppBackupException(validation);
    }
    final plaintext = _encodeJson(payload);
    return _encodeJson(_crypto.encrypt(plaintext, secret));
  }

  Future<AppBackupImportResult> importBackup(
    Uint8List bytes, {
    String? password,
  }) async {
    final document = _decodeDocument(bytes);
    final payload = _extractPayload(document, password: password);
    final hosts = _parseHosts(payload['hosts']);
    final sortMode = _parseSortMode(payload['hostSortMode']);
    final manualOrder = _parseStringList(payload['hostManualOrder']);
    final trustedKeys = _parseTrustedKeys(payload['trustedHostKeys']);

    await _hostsController.mergeImported(
      hosts: hosts,
      sortMode: sortMode,
      manualOrder: manualOrder,
    );
    await _hostKeyVerifier.saveTrustedKeys([
      ...await _hostKeyVerifier.loadTrustedKeys(),
      ...trustedKeys,
    ]);
    await _restoreTheme(payload['theme']);

    return AppBackupImportResult(
      hostsImported: hosts.length,
      trustedKeysImported: trustedKeys.length,
    );
  }

  Future<Map<String, Object?>> _payload({required bool includeSecrets}) async {
    final trustedKeys = await _hostKeyVerifier.loadTrustedKeys();
    return {
      'hosts': [
        for (final host in _hostsController.hosts)
          _hostForBackup(host, includeSecrets: includeSecrets).toJson(),
      ],
      'hostSortMode': _hostsController.sortMode.name,
      'hostManualOrder': _hostsController.manualOrder,
      'theme': _themeToJson(includeSecrets: includeSecrets),
      'trustedHostKeys': [for (final record in trustedKeys) record.toJson()],
    };
  }

  SavedHost _hostForBackup(SavedHost host, {required bool includeSecrets}) {
    if (includeSecrets) {
      return host;
    }
    return host.copyWith(
      password: '',
      privateKey: '',
      passphrase: '',
      hardwareKeys: [
        for (final key in host.hardwareKeys)
          HardwareKeyEntry(id: key.id, label: key.label, privateKey: ''),
      ],
      snippets: [
        for (final snippet in host.snippets) _snippetForBackup(snippet),
      ],
    );
  }

  TerminalSnippet _snippetForBackup(TerminalSnippet snippet) {
    return snippet.hidden ? snippet.copyWith(text: '') : snippet;
  }

  Map<String, Object?> _themeToJson({required bool includeSecrets}) {
    return {
      'themeMode': _themeController.themeMode.name,
      'palette': _themeController.palette.name,
      'terminalFont': _themeController.terminalFont.name,
      'terminalFontSize': _themeController.terminalFontSize,
      'terminalKeyboardRows': [
        for (final row in _themeController.terminalKeyboardRows)
          {
            'height': row.height,
            'items': [for (final item in row.items) _keyboardItemToJson(item)],
          },
      ],
      'terminalSnippets': [
        for (final snippet in _themeController.terminalSnippets)
          (includeSecrets ? snippet : _snippetForBackup(snippet)).toJson(),
      ],
      'showLocalShell': _themeController.showLocalShell,
    };
  }

  Future<void> _restoreTheme(Object? raw) async {
    if (raw is! Map<Object?, Object?>) {
      return;
    }
    final json = Map<String, Object?>.from(raw);
    await _themeController.setThemeMode(
      ThemeMode.values.firstWhere(
        (mode) => mode.name == json['themeMode'],
        orElse: () => _themeController.themeMode,
      ),
    );
    await _themeController.setPalette(
      AppPalette.values.firstWhere(
        (palette) => palette.name == json['palette'],
        orElse: () => _themeController.palette,
      ),
    );
    await _themeController.setTerminalFont(
      TerminalFontOption.values.firstWhere(
        (font) => font.name == json['terminalFont'],
        orElse: () => _themeController.terminalFont,
      ),
    );
    final fontSize = json['terminalFontSize'];
    if (fontSize is num) {
      await _themeController.setTerminalFontSize(fontSize.toDouble());
    }
    final keyboardRows = _parseKeyboardRows(json['terminalKeyboardRows']);
    if (keyboardRows.isNotEmpty) {
      await _themeController.setTerminalKeyboardRows(keyboardRows);
    } else {
      final keyboardItems = _parseKeyboardItems(json['terminalKeyboardItems']);
      if (keyboardItems.isNotEmpty) {
        await _themeController.setTerminalKeyboardRows([
          TerminalKeyboardRow(items: keyboardItems),
        ]);
      }
    }
    final snippets = _parseSnippets(json['terminalSnippets']);
    await _themeController.setTerminalSnippets(snippets);
    final showLocalShell = json['showLocalShell'];
    if (showLocalShell is bool) {
      await _themeController.setShowLocalShell(showLocalShell);
    }
  }

  Map<String, Object?> _decodeDocument(Uint8List bytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is Map<Object?, Object?>) {
        return Map<String, Object?>.from(decoded);
      }
      throw const FormatException('Backup root is not an object.');
    } catch (error) {
      throw const AppBackupException(
        'This does not look like a Conduit backup.',
      );
    }
  }

  Map<String, Object?> _extractPayload(
    Map<String, Object?> document, {
    String? password,
  }) {
    if (document['format'] != 'conduit.backup' || document['version'] != 1) {
      throw const AppBackupException('This backup format is not supported.');
    }

    if (document['encrypted'] == true) {
      final secret = password ?? '';
      if (secret.isEmpty) {
        throw const AppBackupException('Enter the backup password.');
      }
      try {
        final plaintext = _crypto.decrypt(document, secret);
        final decoded = jsonDecode(utf8.decode(plaintext));
        if (decoded is Map<Object?, Object?>) {
          return Map<String, Object?>.from(decoded);
        }
      } catch (_) {
        throw const AppBackupException(
          'The password is wrong or the backup changed.',
        );
      }
      throw const AppBackupException(
        'The encrypted backup payload is invalid.',
      );
    }

    final payload = document['payload'];
    if (payload is Map<Object?, Object?>) {
      return Map<String, Object?>.from(payload);
    }
    throw const AppBackupException('The backup payload is missing.');
  }

  List<SavedHost> _parseHosts(Object? raw) {
    if (raw is! List) {
      return const [];
    }
    return raw
        .whereType<Map<Object?, Object?>>()
        .map((json) => SavedHost.fromJson(Map<String, Object?>.from(json)))
        .where(_isImportableHost)
        .toList(growable: false);
  }

  bool _isImportableHost(SavedHost host) {
    return host.id.isNotEmpty &&
        host.name.trim().isNotEmpty &&
        host.host.trim().isNotEmpty &&
        host.port > 0 &&
        host.port <= 65535 &&
        host.connectionTimeoutSeconds >= 3 &&
        host.connectionTimeoutSeconds <= 120;
  }

  List<HostKeyRecord> _parseTrustedKeys(Object? raw) {
    if (raw is! List) {
      return const [];
    }
    return raw
        .whereType<Map<Object?, Object?>>()
        .map((json) => HostKeyRecord.fromJson(Map<String, Object?>.from(json)))
        .where(
          (record) => record.host.isNotEmpty && record.fingerprint.isNotEmpty,
        )
        .toList(growable: false);
  }

  HostListSortMode _parseSortMode(Object? raw) {
    return HostListSortMode.values.firstWhere(
      (mode) => mode.name == raw,
      orElse: () => HostListSortMode.lastConnected,
    );
  }

  List<String> _parseStringList(Object? raw) {
    if (raw is! List) {
      return const [];
    }
    return raw.whereType<String>().toList(growable: false);
  }

  List<TerminalKeyboardRow> _parseKeyboardRows(Object? raw) {
    if (raw is! List) {
      return const [];
    }
    final rows = <TerminalKeyboardRow>[];
    for (final rawRow in raw.whereType<Map<Object?, Object?>>()) {
      final row = Map<String, Object?>.from(rawRow);
      final items = _parseKeyboardItems(row['items']);
      if (items.isEmpty) {
        continue;
      }
      final height = row['height'];
      rows.add(
        TerminalKeyboardRow(
          items: items,
          height: height is num
              ? clampTerminalKeyboardRowHeight(height.toDouble())
              : terminalKeyboardRowHeightDefault,
        ),
      );
    }
    return rows;
  }

  List<TerminalKeyboardItem> _parseKeyboardItems(Object? raw) {
    if (raw is! List) {
      return const [];
    }
    return raw
        .whereType<Map<Object?, Object?>>()
        .map((json) => _keyboardItemFromJson(Map<String, Object?>.from(json)))
        .whereType<TerminalKeyboardItem>()
        .toList(growable: false);
  }

  Uint8List _encodeJson(Object? value) {
    const encoder = JsonEncoder.withIndent('  ');
    return Uint8List.fromList(utf8.encode('${encoder.convert(value)}\n'));
  }
}

List<TerminalSnippet> _parseSnippets(Object? raw) {
  if (raw is! List) {
    return const [];
  }
  return raw
      .map(TerminalSnippet.fromJson)
      .whereType<TerminalSnippet>()
      .toList(growable: false);
}

class AppBackupCrypto {
  const AppBackupCrypto();

  static const iterations = 210000;
  static const _keyLength = 32;
  static const _saltLength = 32;
  static const _nonceLength = 24;

  Map<String, Object?> encrypt(Uint8List plaintext, String password) {
    final salt = _randomBytes(_saltLength);
    final nonce = _randomBytes(_nonceLength);
    final key = _pbkdf2HmacSha256(
      utf8.encode(password),
      salt,
      iterations,
      _keyLength,
    );
    final encrypted = SecretBox(key).encrypt(plaintext, nonce: nonce);
    return {
      'format': 'conduit.backup',
      'version': 1,
      'encrypted': true,
      'kdf': {
        'name': 'pbkdf2-hmac-sha256',
        'salt': base64Encode(salt),
        'iterations': iterations,
        'keyLength': _keyLength,
      },
      'cipher': {
        'name': 'secretbox-xsalsa20-poly1305',
        'nonce': base64Encode(encrypted.nonce.asTypedList),
        'ciphertext': base64Encode(encrypted.cipherText.asTypedList),
      },
    };
  }

  Uint8List decrypt(Map<String, Object?> document, String password) {
    final kdf = _requiredMap(document['kdf']);
    final cipher = _requiredMap(document['cipher']);
    if (kdf['name'] != 'pbkdf2-hmac-sha256' ||
        cipher['name'] != 'secretbox-xsalsa20-poly1305') {
      throw const AppBackupException('This encrypted backup is not supported.');
    }
    final salt = base64Decode(kdf['salt'] as String? ?? '');
    final nonce = base64Decode(cipher['nonce'] as String? ?? '');
    final ciphertext = base64Decode(cipher['ciphertext'] as String? ?? '');
    final iterationCount = kdf['iterations'];
    final keyLength = kdf['keyLength'];
    if (iterationCount is! int ||
        keyLength is! int ||
        keyLength != _keyLength) {
      throw const AppBackupException('This encrypted backup is not supported.');
    }
    final key = _pbkdf2HmacSha256(
      utf8.encode(password),
      salt,
      iterationCount,
      keyLength,
    );
    return SecretBox(key).decrypt(
      EncryptedMessage(
        nonce: Uint8List.fromList(nonce),
        cipherText: Uint8List.fromList(ciphertext),
      ),
    );
  }

  static Map<String, Object?> _requiredMap(Object? raw) {
    if (raw is Map<Object?, Object?>) {
      return Map<String, Object?>.from(raw);
    }
    throw const AppBackupException('This encrypted backup is invalid.');
  }

  static Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }

  static Uint8List _pbkdf2HmacSha256(
    List<int> password,
    List<int> salt,
    int iterations,
    int keyLength,
  ) {
    if (iterations <= 0 || keyLength <= 0) {
      throw ArgumentError.value(iterations, 'iterations');
    }
    final hmac = Hmac(sha256, password);
    final blockCount = (keyLength / hmac.convert(<int>[]).bytes.length).ceil();
    final output = <int>[];
    for (var block = 1; block <= blockCount; block += 1) {
      final initial = hmac.convert([...salt, ..._uint32be(block)]).bytes;
      var u = initial;
      final result = List<int>.of(initial);
      for (var i = 1; i < iterations; i += 1) {
        u = hmac.convert(u).bytes;
        for (var j = 0; j < result.length; j += 1) {
          result[j] ^= u[j];
        }
      }
      output.addAll(result);
    }
    return Uint8List.fromList(output.take(keyLength).toList());
  }

  static List<int> _uint32be(int value) {
    return [
      (value >> 24) & 0xff,
      (value >> 16) & 0xff,
      (value >> 8) & 0xff,
      value & 0xff,
    ];
  }
}

class AppBackupPasswordPolicy {
  const AppBackupPasswordPolicy._();

  static String? validate(String password) {
    if (password.length < 12) {
      return 'Use at least 12 characters.';
    }
    if (password.trim() != password) {
      return 'Remove spaces from the start or end.';
    }
    var groups = 0;
    if (RegExp('[a-z]').hasMatch(password)) groups += 1;
    if (RegExp('[A-Z]').hasMatch(password)) groups += 1;
    if (RegExp('[0-9]').hasMatch(password)) groups += 1;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) groups += 1;
    if (groups < 3) {
      return 'Use at least three of lowercase, uppercase, numbers, and symbols.';
    }
    return null;
  }
}

class AppBackupImportResult {
  const AppBackupImportResult({
    required this.hostsImported,
    required this.trustedKeysImported,
  });

  final int hostsImported;
  final int trustedKeysImported;
}

class AppBackupException implements Exception {
  const AppBackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

Map<String, Object?> _keyboardItemToJson(TerminalKeyboardItem item) {
  return {
    'id': item.id,
    'kind': item.kind.name,
    'label': item.label,
    'action': item.action?.name,
    'text': item.text,
    'controlKey': item.controlKey,
    'submit': item.submit,
  };
}

TerminalKeyboardItem? _keyboardItemFromJson(Map<String, Object?> json) {
  final kindName = json['kind'];
  final id = json['id'];
  if (kindName is! String || id is! String) {
    return null;
  }
  final kind = TerminalKeyboardItemKind.values
      .where((candidate) => candidate.name == kindName)
      .firstOrNull;
  if (kind == null) {
    return null;
  }
  switch (kind) {
    case TerminalKeyboardItemKind.builtIn:
      final actionName = json['action'];
      if (actionName is! String) {
        return null;
      }
      final action = TerminalKeyboardAction.values
          .where((candidate) => candidate.name == actionName)
          .firstOrNull;
      return action == null ? null : TerminalKeyboardItem.builtIn(action);
    case TerminalKeyboardItemKind.customText:
      final label = json['label'];
      final text = json['text'];
      if (id.trim().isEmpty ||
          label is! String ||
          text is! String ||
          label.trim().isEmpty) {
        return null;
      }
      return TerminalKeyboardItem(
        id: id,
        kind: kind,
        label: label,
        text: text,
        submit: json['submit'] == true,
      );
    case TerminalKeyboardItemKind.customControl:
      final label = json['label'];
      final controlKey = json['controlKey'];
      if (id.trim().isEmpty ||
          label is! String ||
          controlKey is! String ||
          label.trim().isEmpty ||
          !terminalKeyboardControlKeys.contains(controlKey)) {
        return null;
      }
      return TerminalKeyboardItem(
        id: id,
        kind: kind,
        label: label,
        controlKey: controlKey,
      );
  }
}

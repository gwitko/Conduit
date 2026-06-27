import 'dart:convert';

import 'package:conduit/core/theme/app_palette.dart';
import 'package:conduit/core/theme/terminal_appearance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemePreferences {
  const ThemePreferences({
    required this.themeMode,
    required this.palette,
    this.terminalFont = TerminalFontOption.atkynsonNerdFont,
    this.terminalFontSize = terminalFontSizeDefault,
    this.terminalKeyboardItems = defaultTerminalKeyboardItems,
    this.showLocalShell = true,
  });

  final ThemeMode themeMode;
  final AppPalette palette;
  final TerminalFontOption terminalFont;
  final double terminalFontSize;
  final List<TerminalKeyboardItem> terminalKeyboardItems;
  final bool showLocalShell;
}

class ThemePreferencesRepository {
  const ThemePreferencesRepository(this._storage);

  static const _themeModeKey = 'conduit.theme_mode.v1';
  static const _paletteKey = 'conduit.palette.v1';
  static const _terminalFontKey = 'conduit.terminal_font.v1';
  static const _terminalFontSizeKey = 'conduit.terminal_font_size.v1';
  static const _terminalKeyboardActionsKey =
      'conduit.terminal_keyboard_actions.v1';
  static const _showLocalShellKey = 'conduit.show_local_shell.v1';

  final FlutterSecureStorage _storage;

  Future<ThemePreferences> load() async {
    final rawMode = await _storage.read(key: _themeModeKey);
    final rawPalette = await _storage.read(key: _paletteKey);
    final rawTerminalFont = await _storage.read(key: _terminalFontKey);
    final rawTerminalFontSize = await _storage.read(key: _terminalFontSizeKey);
    final rawTerminalKeyboardActions = await _storage.read(
      key: _terminalKeyboardActionsKey,
    );
    final rawShowLocalShell = await _storage.read(key: _showLocalShellKey);
    final terminalFontSize = double.tryParse(rawTerminalFontSize ?? '');
    final terminalKeyboardItems = _parseTerminalKeyboardItems(
      rawTerminalKeyboardActions,
    );

    return ThemePreferences(
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == rawMode,
        orElse: () => ThemeMode.dark,
      ),
      palette: AppPalette.values.firstWhere(
        (palette) => palette.name == rawPalette,
        orElse: () => AppPalette.synthwave,
      ),
      terminalFont: TerminalFontOption.values.firstWhere(
        (font) => font.name == rawTerminalFont,
        orElse: () => TerminalFontOption.atkynsonNerdFont,
      ),
      terminalFontSize: terminalFontSize == null
          ? terminalFontSizeDefault
          : clampTerminalFontSize(terminalFontSize),
      terminalKeyboardItems: terminalKeyboardItems,
      showLocalShell: rawShowLocalShell == null || rawShowLocalShell == 'true',
    );
  }

  Future<void> save(ThemePreferences preferences) async {
    await _storage.write(key: _themeModeKey, value: preferences.themeMode.name);
    await _storage.write(key: _paletteKey, value: preferences.palette.name);
    await _storage.write(
      key: _terminalFontKey,
      value: preferences.terminalFont.name,
    );
    await _storage.write(
      key: _terminalFontSizeKey,
      value: preferences.terminalFontSize.toStringAsFixed(1),
    );
    await _storage.write(
      key: _terminalKeyboardActionsKey,
      value: jsonEncode(
        preferences.terminalKeyboardItems.map(_keyboardItemToJson).toList(),
      ),
    );
    await _storage.write(
      key: _showLocalShellKey,
      value: preferences.showLocalShell.toString(),
    );
  }

  List<TerminalKeyboardItem> _parseTerminalKeyboardItems(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return defaultTerminalKeyboardItems;
    }

    final trimmed = raw.trim();
    if (trimmed.startsWith('[')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is List) {
          final items = <TerminalKeyboardItem>[];
          final seenBuiltIns = <TerminalKeyboardAction>{};
          for (final rawItem in decoded) {
            if (rawItem is! Map) {
              continue;
            }
            final item = _keyboardItemFromJson(
              Map<String, Object?>.from(rawItem),
            );
            if (item == null) {
              continue;
            }
            final action = item.action;
            if (item.kind == TerminalKeyboardItemKind.builtIn &&
                action != null &&
                !seenBuiltIns.add(action)) {
              continue;
            }
            items.add(item);
          }
          if (items.isNotEmpty) {
            return items;
          }
        }
      } catch (_) {
        return defaultTerminalKeyboardItems;
      }
    }

    final actions = <TerminalKeyboardAction>[];
    for (final name in trimmed.split(',')) {
      TerminalKeyboardAction? action;
      for (final candidate in TerminalKeyboardAction.values) {
        if (candidate.name == name.trim()) {
          action = candidate;
          break;
        }
      }
      if (action != null && !actions.contains(action)) {
        actions.add(action);
      }
    }

    if (actions.isEmpty ||
        _sameActions(actions, legacyDefaultTerminalKeyboardActions)) {
      return defaultTerminalKeyboardItems;
    }
    return [for (final action in actions) TerminalKeyboardItem.builtIn(action)];
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

  bool _sameActions(
    List<TerminalKeyboardAction> first,
    List<TerminalKeyboardAction> second,
  ) {
    if (first.length != second.length) {
      return false;
    }
    for (var index = 0; index < first.length; index += 1) {
      if (first[index] != second[index]) {
        return false;
      }
    }
    return true;
  }
}

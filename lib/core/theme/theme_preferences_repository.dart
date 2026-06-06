import 'package:conduit/core/theme/app_palette.dart';
import 'package:conduit/core/theme/terminal_appearance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemePreferences {
  const ThemePreferences({
    required this.themeMode,
    required this.palette,
    this.terminalFont = TerminalFontOption.atkynsonNerdFont,
    this.terminalFontSize = 13.5,
    this.terminalKeyboardActions = defaultTerminalKeyboardActions,
  });

  final ThemeMode themeMode;
  final AppPalette palette;
  final TerminalFontOption terminalFont;
  final double terminalFontSize;
  final List<TerminalKeyboardAction> terminalKeyboardActions;
}

class ThemePreferencesRepository {
  const ThemePreferencesRepository(this._storage);

  static const _themeModeKey = 'conduit.theme_mode.v1';
  static const _paletteKey = 'conduit.palette.v1';
  static const _terminalFontKey = 'conduit.terminal_font.v1';
  static const _terminalFontSizeKey = 'conduit.terminal_font_size.v1';
  static const _terminalKeyboardActionsKey =
      'conduit.terminal_keyboard_actions.v1';

  final FlutterSecureStorage _storage;

  Future<ThemePreferences> load() async {
    final rawMode = await _storage.read(key: _themeModeKey);
    final rawPalette = await _storage.read(key: _paletteKey);
    final rawTerminalFont = await _storage.read(key: _terminalFontKey);
    final rawTerminalFontSize = await _storage.read(key: _terminalFontSizeKey);
    final rawTerminalKeyboardActions = await _storage.read(
      key: _terminalKeyboardActionsKey,
    );
    final terminalFontSize = double.tryParse(rawTerminalFontSize ?? '');
    final terminalKeyboardActions = _parseTerminalKeyboardActions(
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
          ? 13.5
          : terminalFontSize.clamp(10, 22).toDouble(),
      terminalKeyboardActions: terminalKeyboardActions,
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
      value: preferences.terminalKeyboardActions
          .map((action) => action.name)
          .join(','),
    );
  }

  List<TerminalKeyboardAction> _parseTerminalKeyboardActions(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return defaultTerminalKeyboardActions;
    }

    final actions = <TerminalKeyboardAction>[];
    for (final name in raw.split(',')) {
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
      return defaultTerminalKeyboardActions;
    }
    return actions;
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

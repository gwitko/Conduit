import 'package:conduit/core/theme/app_palette.dart';
import 'package:conduit/core/theme/terminal_appearance.dart';
import 'package:conduit/core/theme/theme_preferences_repository.dart';
import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  ThemeController(this._repository);

  final ThemePreferencesRepository _repository;

  ThemeMode _themeMode = ThemeMode.dark;
  AppPalette _palette = AppPalette.synthwave;
  TerminalFontOption _terminalFont = TerminalFontOption.atkynsonNerdFont;
  double _terminalFontSize = terminalFontSizeDefault;
  List<TerminalKeyboardItem> _terminalKeyboardItems =
      defaultTerminalKeyboardItems;
  bool _showLocalShell = true;

  ThemeMode get themeMode => _themeMode;
  AppPalette get palette => _palette;
  TerminalFontOption get terminalFont => _terminalFont;
  double get terminalFontSize => _terminalFontSize;
  List<TerminalKeyboardItem> get terminalKeyboardItems =>
      List.unmodifiable(_terminalKeyboardItems);
  bool get showLocalShell => _showLocalShell;

  Future<void> load() async {
    final preferences = await _repository.load();
    _themeMode = preferences.themeMode;
    _palette = preferences.palette;
    _terminalFont = preferences.terminalFont;
    _terminalFontSize = preferences.terminalFontSize;
    _terminalKeyboardItems = List.of(preferences.terminalKeyboardItems);
    _showLocalShell = preferences.showLocalShell;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) {
      return;
    }
    _themeMode = mode;
    notifyListeners();
    await _save();
  }

  Future<void> setPalette(AppPalette palette) async {
    if (_palette == palette) {
      return;
    }
    _palette = palette;
    notifyListeners();
    await _save();
  }

  Future<void> setTerminalFont(TerminalFontOption font) async {
    if (_terminalFont == font) {
      return;
    }
    _terminalFont = font;
    notifyListeners();
    await _save();
  }

  Future<void> setTerminalFontSize(double size) async {
    final normalized = normalizeTerminalFontSize(size);
    if (_terminalFontSize == normalized) {
      return;
    }
    _terminalFontSize = normalized;
    notifyListeners();
    await _save();
  }

  Future<void> setTerminalKeyboardItems(
    List<TerminalKeyboardItem> items,
  ) async {
    final seen = <TerminalKeyboardAction>{};
    final normalized = <TerminalKeyboardItem>[];
    for (final item in items) {
      final action = item.action;
      if (item.kind == TerminalKeyboardItemKind.builtIn && action != null) {
        if (seen.add(action)) {
          normalized.add(item);
        }
      } else {
        normalized.add(item);
      }
    }
    final next = normalized.isEmpty ? defaultTerminalKeyboardItems : normalized;
    if (_listEquals(_terminalKeyboardItems, next)) {
      return;
    }
    _terminalKeyboardItems = List.of(next);
    notifyListeners();
    await _save();
  }

  Future<void> resetTerminalKeyboardItems() {
    return setTerminalKeyboardItems(defaultTerminalKeyboardItems);
  }

  Future<void> setShowLocalShell(bool show) async {
    if (_showLocalShell == show) {
      return;
    }
    _showLocalShell = show;
    notifyListeners();
    await _save();
  }

  Future<void> _save() {
    return _repository.save(
      ThemePreferences(
        themeMode: _themeMode,
        palette: _palette,
        terminalFont: _terminalFont,
        terminalFontSize: _terminalFontSize,
        terminalKeyboardItems: _terminalKeyboardItems,
        showLocalShell: _showLocalShell,
      ),
    );
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i += 1) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}

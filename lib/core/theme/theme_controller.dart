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
  double _terminalFontSize = 13.5;
  List<TerminalKeyboardAction> _terminalKeyboardActions =
      defaultTerminalKeyboardActions;

  ThemeMode get themeMode => _themeMode;
  AppPalette get palette => _palette;
  TerminalFontOption get terminalFont => _terminalFont;
  double get terminalFontSize => _terminalFontSize;
  List<TerminalKeyboardAction> get terminalKeyboardActions =>
      List.unmodifiable(_terminalKeyboardActions);

  Future<void> load() async {
    final preferences = await _repository.load();
    _themeMode = preferences.themeMode;
    _palette = preferences.palette;
    _terminalFont = preferences.terminalFont;
    _terminalFontSize = preferences.terminalFontSize;
    _terminalKeyboardActions = List.of(preferences.terminalKeyboardActions);
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
    final normalized = (size * 2).round() / 2;
    if (_terminalFontSize == normalized) {
      return;
    }
    _terminalFontSize = normalized.clamp(10, 22).toDouble();
    notifyListeners();
    await _save();
  }

  Future<void> setTerminalKeyboardActions(
    List<TerminalKeyboardAction> actions,
  ) async {
    final seen = <TerminalKeyboardAction>{};
    final normalized = <TerminalKeyboardAction>[];
    for (final action in actions) {
      if (seen.add(action)) {
        normalized.add(action);
      }
    }
    final next = normalized.isEmpty
        ? defaultTerminalKeyboardActions
        : normalized;
    if (_listEquals(_terminalKeyboardActions, next)) {
      return;
    }
    _terminalKeyboardActions = List.of(next);
    notifyListeners();
    await _save();
  }

  Future<void> resetTerminalKeyboardActions() {
    return setTerminalKeyboardActions(defaultTerminalKeyboardActions);
  }

  Future<void> _save() {
    return _repository.save(
      ThemePreferences(
        themeMode: _themeMode,
        palette: _palette,
        terminalFont: _terminalFont,
        terminalFontSize: _terminalFontSize,
        terminalKeyboardActions: _terminalKeyboardActions,
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

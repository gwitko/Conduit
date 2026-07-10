import 'package:conduit/core/theme/app_palette.dart';
import 'package:conduit/core/theme/terminal_appearance.dart';
import 'package:conduit/core/theme/theme_preferences_repository.dart';
import 'package:conduit/features/snippets/domain/terminal_snippet.dart';
import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  ThemeController(this._repository);

  final ThemePreferencesRepository _repository;

  ThemeMode _themeMode = ThemeMode.dark;
  AppPalette _palette = AppPalette.synthwave;
  TerminalFontOption _terminalFont = TerminalFontOption.atkynsonNerdFont;
  double _terminalFontSize = terminalFontSizeDefault;
  List<TerminalKeyboardRow> _terminalKeyboardRows = defaultTerminalKeyboardRows;
  List<TerminalSnippet> _terminalSnippets = const [];
  bool _showLocalShell = true;

  ThemeMode get themeMode => _themeMode;
  AppPalette get palette => _palette;
  TerminalFontOption get terminalFont => _terminalFont;
  double get terminalFontSize => _terminalFontSize;
  List<TerminalKeyboardRow> get terminalKeyboardRows =>
      List.unmodifiable(_terminalKeyboardRows);
  List<TerminalSnippet> get terminalSnippets =>
      List.unmodifiable(_terminalSnippets);
  bool get showLocalShell => _showLocalShell;

  Future<void> load() async {
    final preferences = await _repository.load();
    _themeMode = preferences.themeMode;
    _palette = preferences.palette;
    _terminalFont = preferences.terminalFont;
    _terminalFontSize = preferences.terminalFontSize;
    _terminalKeyboardRows = List.of(preferences.terminalKeyboardRows);
    _terminalSnippets = List.of(preferences.terminalSnippets);
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

  Future<void> setTerminalKeyboardRows(List<TerminalKeyboardRow> rows) async {
    final normalized = <TerminalKeyboardRow>[];
    for (final row in rows) {
      final seen = <TerminalKeyboardAction>{};
      final items = <TerminalKeyboardItem>[];
      for (final item in row.items) {
        final action = item.action;
        if (item.kind == TerminalKeyboardItemKind.builtIn && action != null) {
          if (seen.add(action)) {
            items.add(item);
          }
        } else {
          items.add(item);
        }
      }
      if (items.isEmpty) {
        continue;
      }
      normalized.add(
        TerminalKeyboardRow(
          items: items,
          height: clampTerminalKeyboardRowHeight(row.height),
        ),
      );
    }
    final next = normalized.isEmpty ? defaultTerminalKeyboardRows : normalized;
    if (_listEquals(_terminalKeyboardRows, next)) {
      return;
    }
    _terminalKeyboardRows = List.of(next);
    notifyListeners();
    await _save();
  }

  Future<void> resetTerminalKeyboardRows() {
    return setTerminalKeyboardRows(defaultTerminalKeyboardRows);
  }

  Future<void> setTerminalSnippets(List<TerminalSnippet> snippets) async {
    final seen = <String>{};
    final normalized = <TerminalSnippet>[];
    for (final snippet in snippets) {
      if (!snippet.isValid || !seen.add(snippet.id)) {
        continue;
      }
      normalized.add(snippet);
    }
    if (_listEquals(_terminalSnippets, normalized)) {
      return;
    }
    _terminalSnippets = List.of(normalized);
    notifyListeners();
    await _save();
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
        terminalKeyboardRows: _terminalKeyboardRows,
        terminalSnippets: _terminalSnippets,
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

import 'dart:convert';

import 'package:conduit/core/theme/app_palette.dart';
import 'package:conduit/core/theme/terminal_appearance.dart';
import 'package:conduit/features/snippets/domain/terminal_snippet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemePreferences {
  const ThemePreferences({
    required this.themeMode,
    required this.palette,
    this.terminalFont = TerminalFontOption.atkynsonNerdFont,
    this.terminalFontSize = terminalFontSizeDefault,
    this.terminalKeyboardRows = defaultTerminalKeyboardRows,
    this.terminalSnippets = const [],
    this.showLocalShell = true,
  });

  final ThemeMode themeMode;
  final AppPalette palette;
  final TerminalFontOption terminalFont;
  final double terminalFontSize;
  final List<TerminalKeyboardRow> terminalKeyboardRows;
  final List<TerminalSnippet> terminalSnippets;
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
  static const _terminalKeyboardRowsKey = 'conduit.terminal_keyboard_rows.v1';
  static const _terminalKeyboardSeenActionsKey =
      'conduit.terminal_keyboard_seen_actions.v1';
  static const _terminalSnippetsKey = 'conduit.terminal_snippets.v1';
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
    final rawTerminalKeyboardRows = await _storage.read(
      key: _terminalKeyboardRowsKey,
    );
    final rawTerminalKeyboardSeenActions = await _storage.read(
      key: _terminalKeyboardSeenActionsKey,
    );
    final rawTerminalSnippets = await _storage.read(key: _terminalSnippetsKey);
    final rawShowLocalShell = await _storage.read(key: _showLocalShellKey);
    final terminalFontSize = double.tryParse(rawTerminalFontSize ?? '');
    final terminalKeyboardRows = _appendUnseenBuiltIns(
      _parseTerminalKeyboardRows(
        rawTerminalKeyboardRows,
        rawTerminalKeyboardActions,
      ),
      _parseSeenActionNames(rawTerminalKeyboardSeenActions),
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
      terminalKeyboardRows: terminalKeyboardRows,
      terminalSnippets: _parseTerminalSnippets(rawTerminalSnippets),
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
      key: _terminalKeyboardRowsKey,
      value: jsonEncode([
        for (final row in preferences.terminalKeyboardRows)
          {
            'height': row.height,
            'items': row.items.map(_keyboardItemToJson).toList(),
          },
      ]),
    );
    await _storage.write(
      key: _terminalKeyboardSeenActionsKey,
      value: TerminalKeyboardAction.values
          .map((action) => action.name)
          .join(','),
    );
    await _storage.write(
      key: _terminalSnippetsKey,
      value: jsonEncode(
        preferences.terminalSnippets
            .map((snippet) => snippet.toJson())
            .toList(),
      ),
    );
    await _storage.write(
      key: _showLocalShellKey,
      value: preferences.showLocalShell.toString(),
    );
  }

  List<TerminalSnippet> _parseTerminalSnippets(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }
      return decoded
          .map(TerminalSnippet.fromJson)
          .whereType<TerminalSnippet>()
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  List<TerminalKeyboardRow> _parseTerminalKeyboardRows(
    String? rawRows,
    String? rawLegacyItems,
  ) {
    if (rawRows == null || rawRows.trim().isEmpty) {
      return [
        TerminalKeyboardRow(items: _parseTerminalKeyboardItems(rawLegacyItems)),
      ];
    }
    try {
      final decoded = jsonDecode(rawRows);
      if (decoded is! List) {
        return defaultTerminalKeyboardRows;
      }
      final rows = <TerminalKeyboardRow>[];
      for (final rawRow in decoded) {
        if (rawRow is! Map) {
          continue;
        }
        final rawItems = rawRow['items'];
        if (rawItems is! List) {
          continue;
        }
        final seenBuiltIns = <TerminalKeyboardAction>{};
        final items = <TerminalKeyboardItem>[];
        for (final rawItem in rawItems) {
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
        if (items.isEmpty) {
          continue;
        }
        final rawHeight = rawRow['height'];
        rows.add(
          TerminalKeyboardRow(
            items: items,
            height: rawHeight is num
                ? clampTerminalKeyboardRowHeight(rawHeight.toDouble())
                : terminalKeyboardRowHeightDefault,
          ),
        );
      }
      return rows.isEmpty ? defaultTerminalKeyboardRows : rows;
    } catch (_) {
      return defaultTerminalKeyboardRows;
    }
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

  Set<String> _parseSeenActionNames(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return preTrackingTerminalKeyboardActionNames;
    }
    return raw.split(',').map((name) => name.trim()).toSet();
  }

  List<TerminalKeyboardRow> _appendUnseenBuiltIns(
    List<TerminalKeyboardRow> rows,
    Set<String> seenActionNames,
  ) {
    final present = <TerminalKeyboardAction>{
      for (final row in rows)
        for (final item in row.items)
          if (item.action != null) item.action!,
    };
    final unseen = TerminalKeyboardAction.values
        .where(
          (action) =>
              !seenActionNames.contains(action.name) &&
              !present.contains(action),
        )
        .toList(growable: false);
    if (unseen.isEmpty || rows.isEmpty) {
      return rows;
    }
    final first = rows.first;
    return [
      first.copyWith(
        items: [
          ...first.items,
          for (final action in unseen) TerminalKeyboardItem.builtIn(action),
        ],
      ),
      ...rows.skip(1),
    ];
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

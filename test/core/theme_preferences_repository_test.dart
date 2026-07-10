import 'package:conduit/core/theme/app_palette.dart';
import 'package:conduit/core/theme/terminal_appearance.dart';
import 'package:conduit/core/theme/theme_preferences_repository.dart';
import 'package:conduit/features/snippets/domain/terminal_snippet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_doubles.dart';

void main() {
  group('ThemePreferencesRepository', () {
    test(
      'loads legacy comma-separated keyboard actions as built-in items',
      () async {
        final storage = InMemorySecureStorage();
        await storage.write(
          key: 'conduit.terminal_keyboard_actions.v1',
          value: 'escape,control,arrowDown',
        );
        final repository = ThemePreferencesRepository(storage);

        final preferences = await repository.load();

        expect(preferences.terminalKeyboardRows, hasLength(1));
        expect(
          preferences.terminalKeyboardRows.first.items.map(
            (item) => item.action,
          ),
          [
            TerminalKeyboardAction.escape,
            TerminalKeyboardAction.control,
            TerminalKeyboardAction.arrowDown,
            TerminalKeyboardAction.snippets,
          ],
        );
      },
    );

    test('appends built-in keys introduced after a layout was saved', () async {
      final storage = InMemorySecureStorage();
      await storage.write(
        key: 'conduit.terminal_keyboard_actions.v1',
        value: '[{"id":"builtIn:escape","kind":"builtIn","action":"escape"}]',
      );
      final repository = ThemePreferencesRepository(storage);

      final preferences = await repository.load();

      expect(preferences.terminalKeyboardRows, [
        const TerminalKeyboardRow(
          items: [
            TerminalKeyboardItem.builtIn(TerminalKeyboardAction.escape),
            TerminalKeyboardItem.builtIn(TerminalKeyboardAction.snippets),
          ],
        ),
      ]);
    });

    test('does not re-append keys removed after they were seen', () async {
      final storage = InMemorySecureStorage();
      final repository = ThemePreferencesRepository(storage);

      await repository.save(
        const ThemePreferences(
          themeMode: ThemeMode.dark,
          palette: AppPalette.synthwave,
          terminalKeyboardRows: [
            TerminalKeyboardRow(
              items: [
                TerminalKeyboardItem.builtIn(TerminalKeyboardAction.escape),
              ],
            ),
          ],
        ),
      );

      final preferences = await repository.load();

      expect(preferences.terminalKeyboardRows, [
        const TerminalKeyboardRow(
          items: [TerminalKeyboardItem.builtIn(TerminalKeyboardAction.escape)],
        ),
      ]);
    });

    test('persists and loads keyboard rows with heights', () async {
      final storage = InMemorySecureStorage();
      final repository = ThemePreferencesRepository(storage);
      const custom = TerminalKeyboardItem(
        id: 'custom:test',
        kind: TerminalKeyboardItemKind.customText,
        label: 'gs',
        text: 'git status',
        submit: true,
      );
      const rows = [
        TerminalKeyboardRow(
          items: [
            TerminalKeyboardItem.builtIn(TerminalKeyboardAction.escape),
            custom,
          ],
          height: 60,
        ),
        TerminalKeyboardRow(
          items: [TerminalKeyboardItem.builtIn(TerminalKeyboardAction.control)],
          height: 45,
        ),
      ];

      await repository.save(
        const ThemePreferences(
          themeMode: ThemeMode.dark,
          palette: AppPalette.synthwave,
          terminalKeyboardRows: rows,
        ),
      );

      final preferences = await repository.load();

      expect(preferences.terminalKeyboardRows, rows);
    });

    test('keeps the same built-in key in multiple rows', () async {
      final storage = InMemorySecureStorage();
      final repository = ThemePreferencesRepository(storage);
      const rows = [
        TerminalKeyboardRow(
          items: [TerminalKeyboardItem.builtIn(TerminalKeyboardAction.arrowUp)],
        ),
        TerminalKeyboardRow(
          items: [
            TerminalKeyboardItem.builtIn(TerminalKeyboardAction.arrowUp),
            TerminalKeyboardItem.builtIn(TerminalKeyboardAction.arrowDown),
          ],
        ),
      ];

      await repository.save(
        const ThemePreferences(
          themeMode: ThemeMode.dark,
          palette: AppPalette.synthwave,
          terminalKeyboardRows: rows,
        ),
      );

      final preferences = await repository.load();

      expect(preferences.terminalKeyboardRows, rows);
    });

    test('persists local shell visibility', () async {
      final storage = InMemorySecureStorage();
      final repository = ThemePreferencesRepository(storage);

      await repository.save(
        const ThemePreferences(
          themeMode: ThemeMode.dark,
          palette: AppPalette.synthwave,
          showLocalShell: false,
        ),
      );

      final preferences = await repository.load();

      expect(preferences.showLocalShell, isFalse);
    });

    test('persists and loads global snippets', () async {
      final storage = InMemorySecureStorage();
      final repository = ThemePreferencesRepository(storage);
      const snippet = TerminalSnippet(
        id: 'snippet:one',
        label: 'Deploy',
        text: 'deploy production',
        hidden: true,
      );

      await repository.save(
        const ThemePreferences(
          themeMode: ThemeMode.dark,
          palette: AppPalette.synthwave,
          terminalSnippets: [snippet],
        ),
      );

      final preferences = await repository.load();

      expect(preferences.terminalSnippets, [snippet]);
    });
  });
}

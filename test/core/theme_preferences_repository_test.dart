import 'package:conduit/core/theme/app_palette.dart';
import 'package:conduit/core/theme/terminal_appearance.dart';
import 'package:conduit/core/theme/theme_preferences_repository.dart';
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

        expect(preferences.terminalKeyboardItems.map((item) => item.action), [
          TerminalKeyboardAction.escape,
          TerminalKeyboardAction.control,
          TerminalKeyboardAction.arrowDown,
        ]);
      },
    );

    test('persists and loads custom keyboard items', () async {
      final storage = InMemorySecureStorage();
      final repository = ThemePreferencesRepository(storage);
      const custom = TerminalKeyboardItem(
        id: 'custom:test',
        kind: TerminalKeyboardItemKind.customText,
        label: 'gs',
        text: 'git status',
        submit: true,
      );

      await repository.save(
        const ThemePreferences(
          themeMode: ThemeMode.dark,
          palette: AppPalette.synthwave,
          terminalKeyboardItems: [
            TerminalKeyboardItem.builtIn(TerminalKeyboardAction.escape),
            custom,
          ],
        ),
      );

      final preferences = await repository.load();

      expect(preferences.terminalKeyboardItems, [
        const TerminalKeyboardItem.builtIn(TerminalKeyboardAction.escape),
        custom,
      ]);
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
  });
}

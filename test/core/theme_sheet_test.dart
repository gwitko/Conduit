import 'package:conduit/core/presentation/theme_sheet.dart';
import 'package:conduit/core/theme/terminal_appearance.dart';
import 'package:conduit/core/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_doubles.dart';

void main() {
  testWidgets('appearance sheet toggles local shell visibility', (
    tester,
  ) async {
    final controller = ThemeController(InMemoryThemePreferences());
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () {
                    showThemeSheet(context: context, controller: controller);
                  },
                  child: const Text('Appearance'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Show local shell'),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(find.text('Show local shell'), findsOneWidget);
    expect(controller.showLocalShell, isTrue);

    await tester.tap(find.text('Show local shell'));
    await tester.pumpAndSettle();

    expect(controller.showLocalShell, isFalse);
  });

  testWidgets('key row editor adds and saves a custom text key', (
    tester,
  ) async {
    final controller = ThemeController(InMemoryThemePreferences());
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () {
                    showThemeSheet(context: context, controller: controller);
                  },
                  child: const Text('Appearance'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'Edit'));
    await tester.pumpAndSettle();
    final initialCount = controller.terminalKeyboardItems.length;
    await tester.tap(find.widgetWithText(OutlinedButton, 'Edit'));
    await tester.pumpAndSettle();
    expect(find.text('Key Row ($initialCount)'), findsOneWidget);

    await tester.drag(find.byType(ReorderableListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ActionChip, 'Custom'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'gs');
    await tester.enterText(find.byType(TextField).at(1), 'git status');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();
    expect(find.text('gs'), findsOneWidget);
    expect(find.text('Key Row (${initialCount + 1})'), findsOneWidget);
    expect(controller.terminalKeyboardItems.length, initialCount + 1);
    expect(tester.getTopLeft(find.text('gs')).dy, greaterThanOrEqualTo(0));
    expect(
      tester.getBottomRight(find.text('gs')).dy,
      lessThanOrEqualTo(
        tester.view.physicalSize.height / tester.view.devicePixelRatio,
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Done'));
    await tester.pumpAndSettle();

    final custom = controller.terminalKeyboardItems.first;
    expect(custom.kind, TerminalKeyboardItemKind.customText);
    expect(custom.label, 'gs');
    expect(custom.text, 'git status');
  });
}

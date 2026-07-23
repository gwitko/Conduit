import 'dart:convert';

import 'package:conduit/core/theme/terminal_appearance.dart';
import 'package:conduit/core/theme/theme_controller.dart';
import 'package:conduit/features/terminal/presentation/terminal_page.dart';
import 'package:conduit/features/terminal/presentation/terminal_session_controller.dart';
import 'package:conduit/features/terminal/presentation/terminal_workspace_controller.dart';
import 'package:conduit/features/terminal/presentation/widgets/prompt_composer_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

import '../../support/test_doubles.dart';

class _NoopWakelock extends WakelockPlusPlatformInterface {
  @override
  Future<void> toggle({required bool enable}) async {}

  @override
  Future<bool> get enabled async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WakelockPlusPlatformInterface.instance = _NoopWakelock();

  group('sendComposed', () {
    test('normalizes newlines to CR when bracketed paste is off', () async {
      final session = TrackableTerminalSession();
      final controller = TerminalSessionController(
        host: buildHost('a'),
        repository: ImmediateTerminalRepository(session),
      );
      addTearDown(controller.dispose);
      await controller.connect();

      await controller.sendComposed('echo "hi"\nsecond ☕', submit: false);

      expect(session.sent, [utf8.encode('echo "hi"\rsecond ☕')]);
    });

    test('wraps the payload in bracketed paste markers when the remote '
        'app supports them', () async {
      final session = TrackableTerminalSession();
      final controller = TerminalSessionController(
        host: buildHost('a'),
        repository: ImmediateTerminalRepository(session),
      );
      addTearDown(controller.dispose);
      await controller.connect();
      controller.terminal.write('\x1b[?2004h');

      expect(controller.bracketedPasteSupported, isTrue);
      await controller.sendComposed('line one\nline two \$HOME', submit: false);

      expect(session.sent, [
        utf8.encode('\x1b[200~line one\nline two \$HOME\x1b[201~'),
      ]);
    });

    test('strips embedded paste-end markers so content cannot break out of '
        'bracketed paste', () async {
      final session = TrackableTerminalSession();
      final controller = TerminalSessionController(
        host: buildHost('a'),
        repository: ImmediateTerminalRepository(session),
      );
      addTearDown(controller.dispose);
      await controller.connect();
      controller.terminal.write('\x1b[?2004h');

      await controller.sendComposed(
        'safe\x1b[201~\x1b[200~; rm -rf ~\ntail',
        submit: false,
      );

      expect(session.sent, [
        utf8.encode('\x1b[200~safe\x1b[200~; rm -rf ~\ntail\x1b[201~'),
      ]);
    });

    test('drops trailing newlines so insert-only cannot self-submit', () async {
      final session = TrackableTerminalSession();
      final controller = TerminalSessionController(
        host: buildHost('a'),
        repository: ImmediateTerminalRepository(session),
      );
      addTearDown(controller.dispose);
      await controller.connect();

      await controller.sendComposed('echo hi\n\n', submit: false);

      expect(session.sent, [utf8.encode('echo hi')]);
    });

    test('delivers Enter as a separate write when submitting', () async {
      final session = TrackableTerminalSession();
      final controller = TerminalSessionController(
        host: buildHost('a'),
        repository: ImmediateTerminalRepository(session),
      );
      addTearDown(controller.dispose);
      await controller.connect();
      controller.terminal.write('\x1b[?2004h');

      await controller.sendComposed('prompt text', submit: true);

      expect(session.sent, [
        utf8.encode('\x1b[200~prompt text\x1b[201~'),
        utf8.encode('\r'),
      ]);
    });
  });

  group('Prompt composer sheet', () {
    late TrackableTerminalSession sessionA;
    late TerminalWorkspaceController workspace;
    late ThemeController themeController;

    Future<TerminalSessionController> pumpTerminalPage(
      WidgetTester tester, {
      List<String> hostIds = const ['a'],
    }) async {
      sessionA = TrackableTerminalSession();
      workspace = TerminalWorkspaceController(
        ImmediateTerminalRepository(sessionA),
      );
      themeController = ThemeController(InMemoryThemePreferences());
      TerminalSessionController? first;
      for (final id in hostIds) {
        final session = workspace.open(buildHost(id));
        first ??= session;
        // connect() must run outside the fake-async test zone; otherwise the
        // first frame pump never completes.
        await tester.runAsync(session.connect);
      }
      workspace.activate(first!);
      addTearDown(workspace.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: TerminalPage(
            workspace: workspace,
            themeController: themeController,
          ),
        ),
      );
      await tester.pump();
      return first;
    }

    // pumpAndSettle never settles under the terminal's blinking cursor, so
    // sheet transitions are advanced with bounded pumps instead.
    Future<void> settle(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));
    }

    Future<void> openComposerSheet(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Expand composer'));
      await settle(tester);
    }

    Future<void> enterComposeMode(WidgetTester tester) async {
      await tester.tap(find.text('Compose'));
      await tester.pump();
    }

    Future<void> pumpWithComposeKey(WidgetTester tester) async {
      await pumpTerminalPage(tester);
      await themeController.setTerminalKeyboardRows(const [
        TerminalKeyboardRow(
          items: [
            TerminalKeyboardItem.builtIn(TerminalKeyboardAction.compose),
            TerminalKeyboardItem.builtIn(TerminalKeyboardAction.escape),
          ],
        ),
      ]);
      await tester.pump();
    }

    testWidgets('expand opens the sheet seeded with the inline draft', (
      tester,
    ) async {
      await pumpWithComposeKey(tester);
      await enterComposeMode(tester);

      await tester.enterText(find.byType(TextField), 'draft text');
      await openComposerSheet(tester);

      expect(find.byType(PromptComposerSheet), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(PromptComposerSheet),
          matching: find.text('draft text'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('cancel preserves the draft for reopening', (tester) async {
      await pumpWithComposeKey(tester);
      await enterComposeMode(tester);
      await openComposerSheet(tester);

      await tester.enterText(
        find.descendant(
          of: find.byType(PromptComposerSheet),
          matching: find.byType(TextField),
        ),
        'multi\nline\ndraft',
      );
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      await settle(tester);

      expect(find.byType(PromptComposerSheet), findsNothing);
      await openComposerSheet(tester);
      expect(
        find.descendant(
          of: find.byType(PromptComposerSheet),
          matching: find.text('multi\nline\ndraft'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('insert-only sends the prompt without Enter and clears the '
        'draft', (tester) async {
      await pumpWithComposeKey(tester);
      await enterComposeMode(tester);
      await openComposerSheet(tester);

      await tester.enterText(
        find.descendant(
          of: find.byType(PromptComposerSheet),
          matching: find.byType(TextField),
        ),
        'echo "q\'q" (\$HOME) ✨\nnext',
      );
      await tester.pump();
      await tester.tap(find.text('Insert'));
      await settle(tester);

      expect(find.byType(PromptComposerSheet), findsNothing);
      expect(sessionA.sent, [utf8.encode('echo "q\'q" (\$HOME) ✨\rnext')]);

      // Draft is cleared after a successful send.
      await openComposerSheet(tester);
      expect(find.text('echo "q\'q" (\$HOME) ✨\nnext'), findsNothing);
    });

    testWidgets('insert-and-send presses Enter separately and persists the '
        'preference', (tester) async {
      await pumpWithComposeKey(tester);
      await enterComposeMode(tester);
      await openComposerSheet(tester);

      await tester.tap(find.text('Press Enter after inserting'));
      await tester.pump();
      expect(themeController.composeSubmitEnter, isTrue);

      await tester.enterText(
        find.descendant(
          of: find.byType(PromptComposerSheet),
          matching: find.byType(TextField),
        ),
        'run it',
      );
      await tester.pump();
      await tester.tap(find.text('Insert & Send'));
      await tester.pump(TerminalSessionController.composedEnterDelay);
      await settle(tester);

      expect(sessionA.sent, [utf8.encode('run it'), utf8.encode('\r')]);
    });

    testWidgets('double-tapping send does not send twice', (tester) async {
      await pumpWithComposeKey(tester);
      await enterComposeMode(tester);
      await openComposerSheet(tester);
      await tester.tap(find.text('Press Enter after inserting'));
      await tester.pump();

      await tester.enterText(
        find.descendant(
          of: find.byType(PromptComposerSheet),
          matching: find.byType(TextField),
        ),
        'once only',
      );
      await tester.pump();
      await tester.tap(find.text('Insert & Send'));
      await tester.pump();
      // Second tap lands while the first send is still in flight.
      await tester.tap(find.text('Insert & Send'), warnIfMissed: false);
      await tester.pump(TerminalSessionController.composedEnterDelay);
      await settle(tester);

      expect(sessionA.sent, [utf8.encode('once only'), utf8.encode('\r')]);
    });

    testWidgets('oversized prompts are blocked and kept as drafts', (
      tester,
    ) async {
      await pumpWithComposeKey(tester);
      await enterComposeMode(tester);
      await openComposerSheet(tester);

      final oversized = 'a' * (promptComposerMaxChars + 1);
      await tester.enterText(
        find.descendant(
          of: find.byType(PromptComposerSheet),
          matching: find.byType(TextField),
        ),
        oversized,
      );
      await tester.pump();

      expect(find.textContaining('Too large to send safely'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
      expect(sessionA.sent, isEmpty);
    });

    testWidgets('drafts are isolated per session tab', (tester) async {
      final first = await pumpTerminalPage(tester, hostIds: ['a', 'b']);
      await themeController.setTerminalKeyboardRows(const [
        TerminalKeyboardRow(
          items: [TerminalKeyboardItem.builtIn(TerminalKeyboardAction.compose)],
        ),
      ]);
      await tester.pump();
      final second = workspace.sessions[1];

      await enterComposeMode(tester);
      await tester.enterText(find.byType(TextField), 'draft for a');
      await tester.pump();

      workspace.activate(second);
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller?.text,
        isEmpty,
      );

      await tester.enterText(find.byType(TextField), 'draft for b');
      await tester.pump();

      workspace.activate(first);
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller?.text,
        'draft for a',
      );

      workspace.activate(second);
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller?.text,
        'draft for b',
      );

      // Flush the terminal's debounced resize timer so no timers leak.
      await tester.pump(const Duration(milliseconds: 300));
    });
  });
}

import 'package:conduit/features/local_shell/domain/local_shell_instance.dart';
import 'package:conduit/features/local_shell/domain/local_shell_state.dart';
import 'package:conduit/features/local_shell/presentation/local_shell_controller.dart';
import 'package:conduit/features/local_shell/presentation/local_shell_instance_page.dart';
import 'package:conduit/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeController extends LocalShellController {
  _FakeController(this.events);

  final List<String> events;
  LocalShellInstance? instance = const LocalShellInstance(
    id: 'archlinux',
    distroId: 'archlinux',
    name: 'Arch Linux',
  );

  @override
  List<LocalShellInstance> get instances =>
      instance == null ? const [] : [instance!];

  @override
  LocalShellInstance? instanceById(String instanceId) =>
      instance?.id == instanceId ? instance : null;

  @override
  LocalShellState stateFor(String instanceId) => const LocalShellState(
    stage: LocalShellStage.ready,
    installedVersion: 'test',
    diskUsageBytes: 1024,
  );

  @override
  Future<void> refresh() async {}

  @override
  Future<void> remove(String instanceId) async {
    events.add('remove:$instanceId');
    instance = null;
    notifyListeners();
  }

  @override
  Future<void> rename(String instanceId, String name) async {
    events.add('rename:$instanceId:${name.trim()}');
    instance = instance?.copyWith(name: name.trim());
    notifyListeners();
  }
}

Future<void> _pumpInstancePage(
  WidgetTester tester,
  _FakeController controller,
  List<String> events,
) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => LocalShellInstancePage(
                controller: controller,
                instanceId: 'archlinux',
                onOpenSession: (instance) async =>
                    events.add('open:${instance.id}'),
                onCloseSessions: (instanceId) async =>
                    events.add('close:$instanceId'),
              ),
            ),
          ),
          child: const Text('go'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('go'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opens a new session', (tester) async {
    final events = <String>[];
    final controller = _FakeController(events);
    await _pumpInstancePage(tester, controller, events);

    await tester.tap(find.text('New session'));
    expect(events, ['open:archlinux']);
  });

  testWidgets('closes sessions before removing, then pops', (tester) async {
    final events = <String>[];
    final controller = _FakeController(events);
    await _pumpInstancePage(tester, controller, events);

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove').last);
    await tester.pumpAndSettle();

    expect(events, ['close:archlinux', 'remove:archlinux']);
    expect(find.text('New session'), findsNothing);
  });

  testWidgets('renames via the app bar action', (tester) async {
    final events = <String>[];
    final controller = _FakeController(events);
    await _pumpInstancePage(tester, controller, events);

    await tester.tap(find.byTooltip('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'My Arch');
    await tester.tap(find.text('Rename').last);
    await tester.pumpAndSettle();

    expect(events, ['rename:archlinux:My Arch']);
    expect(find.text('My Arch'), findsOneWidget);
  });
}

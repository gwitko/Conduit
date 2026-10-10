import 'package:conduit/features/local_shell/domain/local_shell_instance.dart';
import 'package:conduit/features/local_shell/domain/local_shell_state.dart';
import 'package:conduit/features/local_shell/presentation/local_shell_controller.dart';
import 'package:conduit/features/local_shell/presentation/widgets/local_shell_section.dart';
import 'package:conduit/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeController extends LocalShellController {
  _FakeController({this.fakeInstances = const [], this.readyIds = const {}});

  final List<LocalShellInstance> fakeInstances;
  final Set<String> readyIds;

  @override
  bool get isChecking => false;

  @override
  List<LocalShellInstance> get instances => fakeInstances;

  @override
  LocalShellInstance? instanceById(String instanceId) {
    for (final instance in fakeInstances) {
      if (instance.id == instanceId) return instance;
    }
    return null;
  }

  @override
  LocalShellState stateFor(String instanceId) => readyIds.contains(instanceId)
      ? const LocalShellState(
          stage: LocalShellStage.ready,
          diskUsageBytes: 2048,
        )
      : LocalShellState.notInstalled;

  @override
  Future<void> refresh() async {}
}

Widget wrap(
  LocalShellController controller, {
  VoidCallback? onAdd,
  Future<void> Function(LocalShellInstance)? onOpen,
  void Function(LocalShellInstance)? onManage,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: LocalShellSection(
        controller: controller,
        activeInstanceIds: const {},
        onAdd: onAdd ?? () {},
        onOpenInstance: onOpen ?? (_) async {},
        onManageInstance: onManage ?? (_) {},
      ),
    ),
  );
}

void main() {
  testWidgets('shows a checking placeholder before probing', (tester) async {
    final controller = LocalShellController();
    await tester.pumpWidget(wrap(controller));

    expect(find.text('Device'), findsOneWidget);
    expect(find.textContaining('Checking'), findsOneWidget);
  });

  testWidgets('prompts setup when no shells exist', (tester) async {
    var added = false;
    final controller = _FakeController();
    await tester.pumpWidget(wrap(controller, onAdd: () => added = true));

    expect(find.text('Set up a local shell'), findsOneWidget);
    await tester.tap(find.text('Set up a local shell'));
    expect(added, isTrue);
  });

  testWidgets('lists instances and routes open and manage taps', (
    tester,
  ) async {
    final opened = <String>[];
    final managed = <String>[];
    final controller = _FakeController(
      fakeInstances: const [
        LocalShellInstance(
          id: 'archlinux',
          distroId: 'archlinux',
          name: 'Arch Linux',
        ),
        LocalShellInstance(id: 'debian-2', distroId: 'debian', name: 'Work'),
      ],
      readyIds: const {'archlinux'},
    );
    await tester.pumpWidget(
      wrap(
        controller,
        onOpen: (instance) async => opened.add(instance.id),
        onManage: (instance) => managed.add(instance.id),
      ),
    );

    expect(find.text('Arch Linux'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
    expect(find.textContaining('setup incomplete'), findsOneWidget);
    expect(find.byTooltip('New local shell'), findsOneWidget);

    await tester.tap(find.text('Arch Linux'));
    expect(opened, ['archlinux']);

    await tester.tap(find.text('Work'));
    expect(managed, ['debian-2']);
  });

  testWidgets('hides itself on unsupported devices', (tester) async {
    final controller = LocalShellController();
    await controller.refresh();
    await tester.pumpWidget(wrap(controller));

    expect(find.text('Device'), findsNothing);
  });
}

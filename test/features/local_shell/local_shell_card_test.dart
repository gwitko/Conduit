import 'package:conduit/features/local_shell/domain/local_shell_state.dart';
import 'package:conduit/features/local_shell/presentation/local_shell_controller.dart';
import 'package:conduit/features/local_shell/presentation/widgets/local_shell_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget wrap(LocalShellController controller, {required VoidCallback onManage}) {
  return MaterialApp(
    home: Scaffold(
      body: LocalShellCard(
        controller: controller,
        active: false,
        onOpenSession: () async {},
        onManage: onManage,
      ),
    ),
  );
}

void main() {
  testWidgets('shows a checking state before probing completes', (
    tester,
  ) async {
    final controller = LocalShellController();
    var managed = false;
    await tester.pumpWidget(wrap(controller, onManage: () => managed = true));

    expect(find.text('Local shell'), findsOneWidget);
    expect(find.textContaining('checking'), findsOneWidget);
    expect(find.textContaining('tap to install'), findsNothing);

    await tester.tap(find.text('Local shell'));
    await tester.pump();
    expect(managed, isFalse);
  });

  testWidgets('shows an install affordance when not installed', (tester) async {
    final controller = _FakeLocalShellController(LocalShellState.notInstalled);
    var managed = false;
    await tester.pumpWidget(wrap(controller, onManage: () => managed = true));

    expect(find.text('Local shell'), findsOneWidget);
    expect(find.textContaining('tap to install'), findsOneWidget);

    await tester.tap(find.text('Local shell'));
    await tester.pump();
    expect(managed, isTrue);
  });

  testWidgets('hides itself on unsupported devices', (tester) async {
    final controller = LocalShellController();
    await controller.refresh();
    await tester.pumpWidget(wrap(controller, onManage: () {}));

    expect(find.text('Local shell'), findsNothing);
  });
}

class _FakeLocalShellController extends LocalShellController {
  _FakeLocalShellController(this._state);

  final LocalShellState _state;

  @override
  LocalShellState get state => _state;
}

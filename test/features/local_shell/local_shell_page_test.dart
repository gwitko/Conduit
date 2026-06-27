import 'package:conduit/features/local_shell/domain/local_shell_state.dart';
import 'package:conduit/features/local_shell/presentation/local_shell_controller.dart';
import 'package:conduit/features/local_shell/presentation/local_shell_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeReadyLocalShellController extends LocalShellController {
  FakeReadyLocalShellController(this.events);

  final List<String> events;
  LocalShellState _fakeState = const LocalShellState(
    stage: LocalShellStage.ready,
    installedVersion: 'test',
    diskUsageBytes: 1024,
  );

  @override
  LocalShellState get state => _fakeState;

  @override
  Future<void> refresh() async {}

  @override
  Future<void> reset() async {
    events.add('reset');
    _fakeState = LocalShellState.notInstalled;
    notifyListeners();
  }
}

void main() {
  group('LocalShellPage', () {
    testWidgets('closes local sessions before removing the environment', (
      tester,
    ) async {
      final events = <String>[];
      final controller = FakeReadyLocalShellController(events);

      await tester.pumpWidget(
        MaterialApp(
          home: LocalShellPage(
            controller: controller,
            onOpenSession: () async {},
            onCloseSession: () async => events.add('close'),
          ),
        ),
      );

      await tester.tap(find.text('Remove local shell'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove').last);
      await tester.pumpAndSettle();

      expect(events, ['close', 'reset']);
      expect(controller.state.stage, LocalShellStage.notInstalled);
    });
  });
}

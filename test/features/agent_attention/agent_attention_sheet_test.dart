import 'package:conduit/features/agent_attention/data/herdr_attention_provider.dart';
import 'package:conduit/features/agent_attention/domain/agent_attention.dart';
import 'package:conduit/features/agent_attention/domain/agent_command_runner.dart';
import 'package:conduit/features/agent_attention/presentation/agent_attention_controller.dart';
import 'package:conduit/features/agent_attention/presentation/agent_attention_sheet.dart';
import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:conduit/features/terminal/presentation/terminal_workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

void main() {
  SavedHost monitoredHost(String id) =>
      buildHost(id).copyWith(agentAttentionEnabled: true);

  Future<
    (AgentAttentionController, ScriptedAgentCommandRunner, List<AgentInfo>)
  >
  pumpSheet(
    WidgetTester tester,
    List<Object> script, {
    bool connect = true,
  }) async {
    final workspace = TerminalWorkspaceController(
      ImmediateTerminalRepository(TrackableTerminalSession()),
    );
    final runner = ScriptedAgentCommandRunner(script);
    final controller = AgentAttentionController(
      workspace: workspace,
      runnerFactory: (_) => runner,
      provider: const HerdrAttentionProvider(),
      pollInterval: const Duration(days: 1),
    );
    addTearDown(controller.dispose);
    addTearDown(workspace.dispose);
    if (connect) {
      final session = workspace.open(monitoredHost('h'));
      await tester.runAsync(session.connect);
      await tester.runAsync(pumpEventQueue);
    }
    final opened = <AgentInfo>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AgentAttentionSheet(
            controller: controller,
            onOpenAgent: (host, agent) => opened.add(agent),
          ),
        ),
      ),
    );
    await tester.pump();
    return (controller, runner, opened);
  }

  testWidgets('shows an empty state when nothing is monitored', (tester) async {
    await pumpSheet(tester, [], connect: false);
    expect(
      find.textContaining('No machines are being monitored'),
      findsOneWidget,
    );
  });

  testWidgets('shows agents with states, kind, and location', (tester) async {
    await pumpSheet(tester, [
      const AgentCommandResult(
        stdout:
            '[{"name": "builder", "kind": "claude-code", "state": "working",'
            ' "workspace_id": "w1", "tab_id": "w1:t2"},'
            ' {"name": "reviewer", "state": "blocked"}]',
        stderr: '',
        exitCode: 0,
      ),
    ]);

    expect(find.text('builder'), findsOneWidget);
    expect(find.text('Working'), findsOneWidget);
    expect(find.text('claude-code · workspace w1 · tab w1:t2'), findsOneWidget);
    expect(find.text('reviewer'), findsOneWidget);
    expect(find.text('Needs input'), findsOneWidget);
  });

  testWidgets('shows the no-agents empty state', (tester) async {
    await pumpSheet(tester, [
      const AgentCommandResult(stdout: '[]', stderr: '', exitCode: 0),
    ]);
    expect(find.textContaining('No agents are running'), findsOneWidget);
  });

  testWidgets('shows the provider-unavailable state', (tester) async {
    await pumpSheet(tester, [
      const AgentCommandResult(
        stdout: '',
        stderr: 'sh: herdr: command not found',
        exitCode: 127,
      ),
    ]);
    expect(find.textContaining('not installed'), findsOneWidget);
  });

  testWidgets('shows the error state', (tester) async {
    await pumpSheet(tester, [StateError('connection reset')]);
    expect(find.textContaining('Could not read agent state'), findsOneWidget);
  });

  testWidgets('tapping an agent invokes the open callback', (tester) async {
    final (_, _, opened) = await pumpSheet(tester, [
      const AgentCommandResult(
        stdout: '[{"name": "builder", "state": "blocked"}]',
        stderr: '',
        exitCode: 0,
      ),
    ]);

    await tester.tap(find.text('builder'));
    await tester.pump();

    expect(opened, hasLength(1));
    expect(opened.single.name, 'builder');
  });
}

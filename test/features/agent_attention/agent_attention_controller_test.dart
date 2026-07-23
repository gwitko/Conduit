import 'dart:async';

import 'package:conduit/features/agent_attention/data/herdr_attention_provider.dart';
import 'package:conduit/features/agent_attention/domain/agent_command_runner.dart';
import 'package:conduit/features/agent_attention/presentation/agent_attention_controller.dart';
import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:conduit/features/terminal/presentation/terminal_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

void main() {
  SavedHost monitoredHost(String id) =>
      buildHost(id).copyWith(agentAttentionEnabled: true);

  AgentCommandResult agents(String json) =>
      AgentCommandResult(stdout: json, stderr: '', exitCode: 0);

  const working = '[{"name": "builder", "state": "working"}]';
  const blocked = '[{"name": "builder", "state": "blocked"}]';
  const done = '[{"name": "builder", "state": "done"}]';

  (
    TerminalWorkspaceController,
    AgentAttentionController,
    ScriptedAgentCommandRunner,
    RecordingAgentNotifier,
  )
  build(List<Object> script, {SavedHost? host}) {
    final workspace = TerminalWorkspaceController(
      ImmediateTerminalRepository(TrackableTerminalSession()),
    );
    final runner = ScriptedAgentCommandRunner(script);
    final notifier = RecordingAgentNotifier();
    final controller = AgentAttentionController(
      workspace: workspace,
      runnerFactory: (_) => runner,
      provider: const HerdrAttentionProvider(),
      notifier: notifier,
      // Far beyond test duration; polls are driven manually via pollNow.
      pollInterval: const Duration(days: 1),
    );
    addTearDown(controller.dispose);
    addTearDown(workspace.dispose);
    return (workspace, controller, runner, notifier);
  }

  test('monitors only enabled, connected, non-local hosts', () async {
    final (workspace, controller, _, _) = build([agents(working)]);

    final enabled = workspace.open(monitoredHost('on'));
    final disabled = workspace.open(buildHost('off'));
    expect(controller.isMonitoring('on'), isFalse);

    await enabled.connect();
    await disabled.connect();
    expect(controller.isMonitoring('on'), isTrue);
    expect(controller.isMonitoring('off'), isFalse);
    expect(controller.monitoredHosts.map((host) => host.id), ['on']);
  });

  test('does not notify for the initial snapshot', () async {
    final (workspace, controller, _, notifier) = build([agents(blocked)]);
    await workspace.open(monitoredHost('h')).connect();
    await pumpEventQueue();

    expect(controller.statusFor('h')?.agents, hasLength(1));
    expect(notifier.shown, isEmpty);
  });

  test('notifies exactly once per transition into needing input', () async {
    final (workspace, controller, _, notifier) = build([
      agents(working),
      agents(blocked),
      agents(blocked),
      agents(working),
      agents(blocked),
    ]);
    await workspace.open(monitoredHost('h')).connect();
    await pumpEventQueue();

    await controller.pollNow('h');
    expect(notifier.shown, hasLength(1));
    expect(notifier.shown.single.$2, 'Agent needs input');
    expect(notifier.shown.single.$3, 'builder on Host h');

    // Unchanged state on the next poll must not re-notify.
    await controller.pollNow('h');
    expect(notifier.shown, hasLength(1));

    // Leaving and re-entering the state notifies again.
    await controller.pollNow('h');
    await controller.pollNow('h');
    expect(notifier.shown, hasLength(2));
  });

  test('notifies when background work finishes', () async {
    final (workspace, controller, _, notifier) = build([
      agents(working),
      agents(done),
    ]);
    await workspace.open(monitoredHost('h')).connect();
    await pumpEventQueue();

    await controller.pollNow('h');
    expect(notifier.shown.single.$2, 'Agent finished');
  });

  test('honors per-host notification toggles', () async {
    final muted = monitoredHost(
      'h',
    ).copyWith(agentNotifyInput: false, agentNotifyFinished: false);
    final (workspace, controller, _, notifier) = build([
      agents(working),
      agents(blocked),
      agents(done),
    ], host: muted);
    await workspace.open(muted).connect();
    await pumpEventQueue();

    await controller.pollNow('h');
    await controller.pollNow('h');
    expect(notifier.shown, isEmpty);
  });

  test('handles agents disappearing between polls', () async {
    final (workspace, controller, _, notifier) = build([
      agents(working),
      agents('[]'),
      agents(blocked),
    ]);
    await workspace.open(monitoredHost('h')).connect();
    await pumpEventQueue();

    await controller.pollNow('h');
    expect(controller.statusFor('h')?.agents, isEmpty);
    expect(notifier.shown, isEmpty);

    // The agent coming back blocked is a fresh transition — notify once.
    await controller.pollNow('h');
    expect(notifier.shown, hasLength(1));
  });

  test('stops polling and reports when Herdr is unavailable', () async {
    final (workspace, controller, _, notifier) = build([
      const AgentCommandResult(
        stdout: '',
        stderr: 'sh: herdr: command not found',
        exitCode: 127,
      ),
    ]);
    await workspace.open(monitoredHost('h')).connect();
    await pumpEventQueue();

    expect(
      controller.statusFor('h')?.unavailableReason,
      contains('not installed'),
    );
    expect(notifier.shown, isEmpty);
  });

  test('keeps known agents and reports transient errors', () async {
    final (workspace, controller, _, _) = build([
      agents(working),
      StateError('connection reset'),
    ]);
    await workspace.open(monitoredHost('h')).connect();
    await pumpEventQueue();

    await controller.pollNow('h');
    final status = controller.statusFor('h')!;
    expect(status.error, contains('connection reset'));
    expect(status.agents, hasLength(1));
  });

  test('attention count reflects agents needing input', () async {
    final (workspace, controller, _, _) = build([
      agents(
        '[{"name": "a", "state": "blocked"},'
        ' {"name": "b", "state": "working"},'
        ' {"name": "c", "state": "blocked"}]',
      ),
    ]);
    await workspace.open(monitoredHost('h')).connect();
    await pumpEventQueue();

    expect(controller.attentionCount, 2);
  });

  test(
    'stops the monitor and closes the runner when the session closes',
    () async {
      final (workspace, controller, runner, _) = build([agents(working)]);
      final session = workspace.open(monitoredHost('h'));
      await session.connect();
      await pumpEventQueue();
      expect(controller.isMonitoring('h'), isTrue);

      unawaited(workspace.close(session));
      await pumpEventQueue();

      expect(controller.isMonitoring('h'), isFalse);
      expect(runner.closeCount, 1);
    },
  );

  test('stops the monitor when the session disconnects', () async {
    final (workspace, controller, _, _) = build([agents(working)]);
    final session = workspace.open(monitoredHost('h'));
    await session.connect();
    await pumpEventQueue();
    expect(controller.isMonitoring('h'), isTrue);

    await session.disconnect();
    await pumpEventQueue();

    expect(controller.isMonitoring('h'), isFalse);
  });

  test('pausing keeps known states so background transitions still notify '
      'once', () async {
    final (workspace, controller, _, notifier) = build([
      agents(working),
      agents(blocked),
    ]);
    await workspace.open(monitoredHost('h')).connect();
    await pumpEventQueue();

    controller.setAppActive(false);
    controller.setAppActive(true);
    await pumpEventQueue();

    expect(notifier.shown, hasLength(1));
  });

  test(
    'resuming the app does not resurrect polling on unavailable hosts',
    () async {
      final (workspace, controller, runner, _) = build([
        const AgentCommandResult(
          stdout: '',
          stderr: 'sh: herdr: command not found',
          exitCode: 127,
        ),
      ]);
      await workspace.open(monitoredHost('h')).connect();
      await pumpEventQueue();
      expect(controller.statusFor('h')?.unavailableReason, isNotNull);
      final commandsAfterDetection = runner.commands.length;

      controller.setAppActive(false);
      controller.setAppActive(true);
      await pumpEventQueue();

      expect(runner.commands.length, commandsAfterDetection);
    },
  );

  test('runs the provider focus command for an agent', () async {
    final (workspace, controller, runner, _) = build([agents(working)]);
    await workspace.open(monitoredHost('h')).connect();
    await pumpEventQueue();

    final agent = controller.statusFor('h')!.agents.single;
    await controller.focusAgent('h', agent);

    expect(runner.commands.last, 'herdr agent focus builder');
  });
}

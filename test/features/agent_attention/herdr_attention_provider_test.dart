import 'package:conduit/core/app_failure.dart';
import 'package:conduit/features/agent_attention/data/herdr_attention_provider.dart';
import 'package:conduit/features/agent_attention/domain/agent_attention.dart';
import 'package:conduit/features/agent_attention/domain/agent_attention_provider.dart';
import 'package:conduit/features/agent_attention/domain/agent_command_runner.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

void main() {
  const provider = HerdrAttentionProvider();

  AgentCommandResult ok(String stdout) =>
      AgentCommandResult(stdout: stdout, stderr: '', exitCode: 0);

  group('HerdrAttentionProvider.parseAgentList', () {
    test('parses a bare array with documented field names', () {
      final agents = HerdrAttentionProvider.parseAgentList('''
        [
          {"name": "builder", "kind": "claude-code", "agent_status": "working",
           "pane_id": "w1:p2", "workspace_id": "w1", "tab_id": "w1:t1"},
          {"name": "reviewer", "agent_status": "blocked"},
          {"name": "researcher", "agent_status": "done"},
          {"name": "helper", "agent_status": "idle"},
          {"name": "mystery", "agent_status": "someday-new-state"}
        ]
      ''');

      expect(agents, hasLength(5));
      expect(agents[0].id, 'w1:p2');
      expect(agents[0].name, 'builder');
      expect(agents[0].kind, 'claude-code');
      expect(agents[0].state, AgentAttentionState.working);
      expect(agents[0].workspace, 'w1');
      expect(agents[0].tab, 'w1:t1');
      expect(agents[1].state, AgentAttentionState.needsInput);
      expect(agents[2].state, AgentAttentionState.finished);
      expect(agents[3].state, AgentAttentionState.idle);
      expect(agents[4].state, AgentAttentionState.unknown);
    });

    test('parses result and agents envelopes', () {
      const item = '{"name": "a", "state": "working"}';
      for (final raw in [
        '{"agents": [$item]}',
        '{"result": {"agents": [$item]}}',
        '{"result": [$item]}',
      ]) {
        final agents = HerdrAttentionProvider.parseAgentList(raw);
        expect(agents, hasLength(1), reason: raw);
        expect(agents.single.state, AgentAttentionState.working, reason: raw);
      }
    });

    test('treats empty output and empty lists as no agents', () {
      expect(HerdrAttentionProvider.parseAgentList(''), isEmpty);
      expect(HerdrAttentionProvider.parseAgentList('[]'), isEmpty);
      expect(HerdrAttentionProvider.parseAgentList('{"agents": []}'), isEmpty);
    });

    test('skips malformed entries but keeps valid ones', () {
      final agents = HerdrAttentionProvider.parseAgentList(
        '[{"name": "ok", "state": "idle"}, {"state": "working"}, 42, "x"]',
      );
      expect(agents, hasLength(1));
      expect(agents.single.name, 'ok');
    });

    test('drops absurd timestamps instead of failing the snapshot', () {
      final agents = HerdrAttentionProvider.parseAgentList(
        '[{"name": "a", "state": "working", '
        '"state_changed_at": 99999999999999999999999}]',
      );
      expect(agents, hasLength(1));
      expect(agents.single.stateChangedAt, isNull);
    });

    test('parses timestamps and sequence numbers when present', () {
      final agents = HerdrAttentionProvider.parseAgentList(
        '[{"name": "a", "state": "working", '
        '"state_changed_at": 1767225600000, "state_seq": 7}]',
      );
      expect(
        agents.single.stateChangedAt,
        DateTime.fromMillisecondsSinceEpoch(1767225600000, isUtc: true),
      );
      expect(agents.single.stateSequence, 7);
    });

    test('throws AppFailure on non-JSON output', () {
      expect(
        () => HerdrAttentionProvider.parseAgentList('herdr: segfault'),
        throwsA(isA<AppFailure>()),
      );
    });

    test('throws AppFailure on an unexpected JSON shape', () {
      expect(
        () => HerdrAttentionProvider.parseAgentList('"just a string"'),
        throwsA(isA<AppFailure>()),
      );
    });
  });

  group('HerdrAttentionProvider.fetchAgents', () {
    test('reports Herdr missing on exit 127', () async {
      final runner = ScriptedAgentCommandRunner([
        const AgentCommandResult(
          stdout: '',
          stderr: 'sh: herdr: command not found',
          exitCode: 127,
        ),
      ]);
      expect(
        () => provider.fetchAgents(runner),
        throwsA(isA<AgentProviderUnavailable>()),
      );
    });

    test('reports an older Herdr on CLI usage errors (exit 2)', () async {
      final runner = ScriptedAgentCommandRunner([
        const AgentCommandResult(
          stdout: '',
          stderr: 'unknown subcommand: agent',
          exitCode: 2,
        ),
      ]);
      expect(
        () => provider.fetchAgents(runner),
        throwsA(isA<AgentProviderUnavailable>()),
      );
    });

    test('surfaces server errors with the JSON message', () async {
      final runner = ScriptedAgentCommandRunner([
        const AgentCommandResult(
          stdout: '',
          stderr: '{"error": {"code": "internal", "message": "socket gone"}}',
          exitCode: 1,
        ),
      ]);
      await expectLater(
        () => provider.fetchAgents(runner),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.toString(),
            'message',
            contains('socket gone'),
          ),
        ),
      );
    });

    test('runs the documented list command and parses agents', () async {
      final runner = ScriptedAgentCommandRunner([
        ok('[{"name": "builder", "state": "working"}]'),
      ]);
      final snapshot = await provider.fetchAgents(runner);
      expect(runner.commands, ['herdr agent list']);
      expect(snapshot.agents.single.name, 'builder');
    });
  });

  group('HerdrAttentionProvider.focusCommand', () {
    test('targets the agent name, quoting when needed', () {
      const provider = HerdrAttentionProvider();
      expect(
        provider.focusCommand(
          const AgentInfo(
            id: 'w1:p1',
            name: 'builder',
            state: AgentAttentionState.idle,
          ),
        ),
        'herdr agent focus builder',
      );
      expect(
        provider.focusCommand(
          const AgentInfo(
            id: 'w1:p1',
            name: r"my agent's \$run",
            state: AgentAttentionState.idle,
          ),
        ),
        r"herdr agent focus 'my agent'\''s \$run'",
      );
    });

    test('falls back to the pane id and hides when neither exists', () {
      const provider = HerdrAttentionProvider();
      expect(
        provider.focusCommand(
          const AgentInfo(
            id: 'w1:p9',
            name: '',
            pane: 'w1:p9',
            state: AgentAttentionState.idle,
          ),
        ),
        'herdr agent focus w1:p9',
      );
      expect(
        provider.focusCommand(
          const AgentInfo(id: 'x', name: '', state: AgentAttentionState.idle),
        ),
        isNull,
      );
    });
  });
}

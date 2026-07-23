import 'dart:convert';

import 'package:conduit/core/app_failure.dart';
import 'package:conduit/features/agent_attention/domain/agent_attention.dart';
import 'package:conduit/features/agent_attention/domain/agent_attention_provider.dart';
import 'package:conduit/features/agent_attention/domain/agent_command_runner.dart';

/// Reads agent state from Herdr's documented machine-readable CLI
/// (`herdr agent list` prints JSON; effective agent states are `idle`,
/// `working`, `blocked`, `done`, and `unknown`).
class HerdrAttentionProvider implements AgentAttentionProvider {
  const HerdrAttentionProvider();

  static const _commandTimeout = Duration(seconds: 10);

  @override
  String get id => 'herdr';

  @override
  String get label => 'Herdr';

  @override
  Future<AgentAttentionSnapshot> fetchAgents(AgentCommandRunner runner) async {
    final result = await runner.run(
      'herdr agent list',
      timeout: _commandTimeout,
    );
    final stderr = result.stderr.trim();
    if (result.exitCode == 127 ||
        stderr.contains('command not found') ||
        stderr.contains('herdr: not found')) {
      throw const AgentProviderUnavailable(
        'Herdr is not installed on this machine.',
      );
    }
    if (result.exitCode == 2) {
      // Herdr exits 2 for CLI usage errors — an older build without
      // `agent list`.
      throw const AgentProviderUnavailable(
        'This Herdr version does not support "herdr agent list".',
      );
    }
    if (result.exitCode != null && result.exitCode != 0) {
      throw AppFailure('Herdr reported an error.', _errorDetail(stderr));
    }
    return AgentAttentionSnapshot(agents: parseAgentList(result.stdout));
  }

  @override
  String? focusCommand(AgentInfo agent) {
    final target = agent.name.isNotEmpty ? agent.name : agent.pane;
    if (target == null || target.isEmpty) {
      return null;
    }
    return 'herdr agent focus ${_shellQuote(target)}';
  }

  /// Parses `herdr agent list` output into agent records.
  ///
  /// Tolerates the envelope evolving across versions: a bare JSON array, an
  /// `{"agents": [...]}` object, or a `{"result": {"agents": [...]}}`
  /// envelope all work, unknown fields are ignored, and malformed entries
  /// are skipped rather than failing the whole snapshot. Completely
  /// unparseable output raises [AppFailure].
  static List<AgentInfo> parseAgentList(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const [];
    }
    Object? decoded;
    try {
      decoded = jsonDecode(trimmed);
    } catch (_) {
      throw const AppFailure('Herdr returned output that is not JSON.');
    }
    final items = _extractAgentItems(decoded);
    if (items == null) {
      throw const AppFailure('Herdr returned JSON in an unexpected shape.');
    }
    final agents = <AgentInfo>[];
    for (final item in items) {
      final agent = _parseAgent(item);
      if (agent != null) {
        agents.add(agent);
      }
    }
    return agents;
  }

  static List<Object?>? _extractAgentItems(Object? decoded) {
    if (decoded is List) {
      return decoded;
    }
    if (decoded is Map) {
      for (final key in const ['agents', 'result']) {
        final value = decoded[key];
        if (value is List) {
          return value;
        }
        if (value is Map) {
          final nested = value['agents'];
          if (nested is List) {
            return nested;
          }
        }
      }
      // An object without any recognizable agent list — treat an explicit
      // empty result as no agents.
      if (decoded['result'] == null && decoded['agents'] == null) {
        return null;
      }
      return const [];
    }
    return null;
  }

  static AgentInfo? _parseAgent(Object? item) {
    if (item is! Map) {
      return null;
    }
    final name = _string(item, const ['name', 'agent', 'agent_name']) ?? '';
    final pane = _string(item, const ['pane_id', 'pane']);
    final id = pane?.isNotEmpty == true ? pane! : name;
    if (id.isEmpty) {
      return null;
    }
    return AgentInfo(
      id: id,
      name: name.isNotEmpty ? name : id,
      kind: _string(item, const ['kind', 'agent_kind', 'agent_type']) ?? '',
      state: _parseState(
        _string(item, const ['state', 'agent_status', 'status']),
      ),
      workspace: _string(item, const ['workspace_id', 'workspace']),
      tab: _string(item, const ['tab_id', 'tab']),
      pane: pane,
      stateChangedAt: _parseTimestamp(
        item['state_changed_at'] ?? item['since'] ?? item['updated_at'],
      ),
      stateSequence: _int(
        item['state_seq'] ?? item['seq'] ?? item['status_seq'],
      ),
    );
  }

  static AgentAttentionState _parseState(String? raw) {
    return switch (raw?.toLowerCase()) {
      'working' || 'running' || 'busy' => AgentAttentionState.working,
      // Herdr reports `blocked` when it recognizes an approval or question
      // UI — the agent is waiting on a human.
      'blocked' || 'waiting' || 'needs_input' => AgentAttentionState.needsInput,
      'done' || 'finished' => AgentAttentionState.finished,
      'idle' || 'ready' => AgentAttentionState.idle,
      _ => AgentAttentionState.unknown,
    };
  }

  static String? _string(Map<Object?, Object?> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  static int? _int(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static DateTime? _parseTimestamp(Object? value) {
    if (value is int) {
      try {
        // Interpret plausibly-sized integers as epoch milliseconds; absurd
        // values are dropped rather than failing the whole snapshot.
        if (value > 100000000000) {
          return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
        }
        return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true);
      } on ArgumentError {
        return null;
      }
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static String _errorDetail(String stderr) {
    if (stderr.isEmpty) {
      return 'no error output';
    }
    try {
      final decoded = jsonDecode(stderr);
      if (decoded is Map) {
        final error = decoded['error'];
        if (error is Map && error['message'] is String) {
          return error['message'] as String;
        }
        if (decoded['message'] is String) {
          return decoded['message'] as String;
        }
      }
    } catch (_) {
      // Fall through to the raw text.
    }
    return stderr.length > 200 ? stderr.substring(0, 200) : stderr;
  }

  static String _shellQuote(String value) {
    if (RegExp(r'^[A-Za-z0-9._:\-]+$').hasMatch(value)) {
      return value;
    }
    return "'${value.replaceAll("'", "'\\''")}'";
  }
}

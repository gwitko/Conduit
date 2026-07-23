// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:conduit/features/agent_attention/domain/agent_attention.dart';
import 'package:conduit/features/agent_attention/domain/agent_attention_notifier.dart';
import 'package:conduit/features/agent_attention/domain/agent_attention_provider.dart';
import 'package:conduit/features/agent_attention/domain/agent_command_runner.dart';
import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:conduit/features/terminal/presentation/terminal_session_controller.dart';
import 'package:conduit/features/terminal/presentation/terminal_workspace_controller.dart';
import 'package:flutter/foundation.dart';

/// Builds a command runner for one host; injected so tests can fake the
/// remote side.
typedef AgentCommandRunnerFactory = AgentCommandRunner Function(SavedHost host);

/// Monitoring status for one host, as shown by the dashboard.
class AgentHostStatus {
  const AgentHostStatus({
    this.loading = false,
    this.agents = const [],
    this.error,
    this.unavailableReason,
    this.updatedAt,
  });

  final bool loading;
  final List<AgentInfo> agents;

  /// Transient fetch error (connection loss, malformed output).
  final String? error;

  /// Set when the provider tooling is missing/too old; polling has stopped.
  final String? unavailableReason;

  final DateTime? updatedAt;
}

/// Watches enabled, connected hosts for agent state changes.
///
/// Polling is deliberately conservative: one in-flight fetch per host
/// (ticks are skipped while a fetch runs), a fixed interval, paused while
/// the app is backgrounded, stopped when the session disconnects or closes,
/// and stopped entirely for a host whose provider tooling is missing.
///
/// Notifications are edge-triggered on state *transitions* by stable agent
/// identity — the first snapshot after monitoring starts never notifies,
/// and an unchanged state is never re-notified.
class AgentAttentionController extends ChangeNotifier {
  AgentAttentionController({
    required TerminalWorkspaceController workspace,
    required AgentCommandRunnerFactory runnerFactory,
    required AgentAttentionProvider provider,
    AgentAttentionNotifier? notifier,
    Duration pollInterval = const Duration(seconds: 15),
  }) : _workspace = workspace,
       _runnerFactory = runnerFactory,
       _provider = provider,
       _notifier = notifier,
       _pollInterval = pollInterval {
    _workspace.addListener(_syncMonitors);
    _syncMonitors();
  }

  final TerminalWorkspaceController _workspace;
  final AgentCommandRunnerFactory _runnerFactory;
  final AgentAttentionProvider _provider;
  final AgentAttentionNotifier? _notifier;
  final Duration _pollInterval;

  final Map<String, _HostMonitor> _monitors = {};
  bool _appActive = true;
  bool _disposed = false;

  AgentAttentionProvider get provider => _provider;

  /// Hosts currently monitored, in workspace order.
  List<SavedHost> get monitoredHosts => [
    for (final session in _workspace.sessions)
      if (_monitors.containsKey(session.host.id)) session.host,
  ];

  bool isMonitoring(String hostId) => _monitors.containsKey(hostId);

  AgentHostStatus? statusFor(String hostId) => _monitors[hostId]?.status;

  /// Agents needing attention across every monitored host.
  int get attentionCount {
    var count = 0;
    for (final monitor in _monitors.values) {
      for (final agent in monitor.status.agents) {
        if (agent.state.needsAttention) {
          count += 1;
        }
      }
    }
    return count;
  }

  /// Pauses polling while the app is backgrounded and resumes (with an
  /// immediate refresh) when it returns. Known agent states are kept, so
  /// transitions that happened in the background still notify exactly once.
  void setAppActive(bool active) {
    if (_appActive == active || _disposed) {
      return;
    }
    _appActive = active;
    for (final monitor in _monitors.values) {
      if (active) {
        _startTimer(monitor);
        unawaited(_poll(monitor));
      } else {
        monitor.timer?.cancel();
        monitor.timer = null;
      }
    }
  }

  Future<void> refresh(String hostId) async {
    final monitor = _monitors[hostId];
    if (monitor == null) {
      return;
    }
    // A manual refresh gives an unavailable provider another chance.
    if (monitor.status.unavailableReason != null) {
      monitor.status = const AgentHostStatus(loading: true);
      _startTimer(monitor);
    }
    await _poll(monitor);
  }

  /// Sends the provider's focus command for [agent], if there is one.
  Future<void> focusAgent(String hostId, AgentInfo agent) async {
    final monitor = _monitors[hostId];
    final command = _provider.focusCommand(agent);
    if (monitor == null || command == null) {
      return;
    }
    try {
      await monitor.runner.run(command, timeout: const Duration(seconds: 10));
    } catch (_) {
      // Focus is best-effort; the agent may have exited since the last poll.
    }
  }

  void _syncMonitors() {
    if (_disposed) {
      return;
    }
    final wanted = <String, TerminalSessionController>{
      for (final session in _workspace.sessions)
        if (session.host.agentAttentionEnabled &&
            !session.host.isLocal &&
            session.isConnected)
          session.host.id: session,
    };

    for (final hostId in _monitors.keys.toList()) {
      if (!wanted.containsKey(hostId)) {
        _stopMonitor(hostId);
      }
    }
    for (final MapEntry(key: hostId, value: session) in wanted.entries) {
      if (!_monitors.containsKey(hostId)) {
        _startMonitor(session);
      }
    }
    notifyListeners();
  }

  void _startMonitor(TerminalSessionController session) {
    final monitor = _HostMonitor(
      host: session.host,
      session: session,
      runner: _runnerFactory(session.host),
    );
    _monitors[session.host.id] = monitor;
    // React to this session disconnecting even when the workspace itself
    // does not notify.
    session.addListener(_syncMonitors);
    if (_appActive) {
      _startTimer(monitor);
      unawaited(_poll(monitor));
    }
  }

  void _stopMonitor(String hostId) {
    final monitor = _monitors.remove(hostId);
    if (monitor == null) {
      return;
    }
    monitor.session.removeListener(_syncMonitors);
    monitor.timer?.cancel();
    monitor.timer = null;
    unawaited(monitor.runner.close());
  }

  void _startTimer(_HostMonitor monitor) {
    monitor.timer?.cancel();
    monitor.timer = Timer.periodic(_pollInterval, (_) {
      unawaited(_poll(monitor));
    });
  }

  @visibleForTesting
  Future<void> pollNow(String hostId) async {
    final monitor = _monitors[hostId];
    if (monitor != null) {
      await _poll(monitor);
    }
  }

  Future<void> _poll(_HostMonitor monitor) async {
    if (_disposed ||
        monitor.fetching ||
        !_monitors.containsKey(monitor.host.id)) {
      return;
    }
    if (!monitor.session.isConnected) {
      _syncMonitors();
      return;
    }
    monitor.fetching = true;
    try {
      final snapshot = await _provider.fetchAgents(monitor.runner);
      if (_disposed || !_monitors.containsKey(monitor.host.id)) {
        return;
      }
      await _applySnapshot(monitor, snapshot);
    } on AgentProviderUnavailable catch (unavailable) {
      monitor.status = AgentHostStatus(
        unavailableReason: unavailable.message,
        updatedAt: DateTime.now(),
      );
      // No point polling a machine without the tooling; a manual refresh or
      // reconnect starts over.
      monitor.timer?.cancel();
      monitor.timer = null;
    } catch (error) {
      monitor.status = AgentHostStatus(
        agents: monitor.status.agents,
        error: error.toString(),
        updatedAt: DateTime.now(),
      );
    } finally {
      monitor.fetching = false;
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  Future<void> _applySnapshot(
    _HostMonitor monitor,
    AgentAttentionSnapshot snapshot,
  ) async {
    if (monitor.sawInitialSnapshot) {
      await _notifyTransitions(monitor, snapshot);
    }
    monitor.lastStates = {
      for (final agent in snapshot.agents) agent.id: agent.state,
    };
    monitor.sawInitialSnapshot = true;
    monitor.status = AgentHostStatus(
      agents: snapshot.agents,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _notifyTransitions(
    _HostMonitor monitor,
    AgentAttentionSnapshot snapshot,
  ) async {
    final notifier = _notifier;
    if (notifier == null) {
      return;
    }
    final host = monitor.host;
    for (final agent in snapshot.agents) {
      final previous = monitor.lastStates[agent.id];
      if (previous == agent.state) {
        continue;
      }
      final needsInput = agent.state.needsAttention && host.agentNotifyInput;
      final finished =
          agent.state == AgentAttentionState.finished &&
          host.agentNotifyFinished;
      if (!needsInput && !finished) {
        continue;
      }
      await notifier.show(
        id: '${host.id}:${agent.id}',
        title: needsInput ? 'Agent needs input' : 'Agent finished',
        // Lock-screen safe: only the agent's display label and machine name.
        body: '${agent.name} on ${host.name}',
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _workspace.removeListener(_syncMonitors);
    for (final hostId in _monitors.keys.toList()) {
      _stopMonitor(hostId);
    }
    super.dispose();
  }
}

class _HostMonitor {
  _HostMonitor({
    required this.host,
    required this.session,
    required this.runner,
  });

  final SavedHost host;
  final TerminalSessionController session;
  final AgentCommandRunner runner;

  Timer? timer;
  bool fetching = false;
  bool sawInitialSnapshot = false;
  Map<String, AgentAttentionState> lastStates = const {};
  AgentHostStatus status = const AgentHostStatus(loading: true);
}

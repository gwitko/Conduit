/// The attention-relevant state of one remote agent, normalized across
/// providers.
enum AgentAttentionState {
  /// Actively producing output or running tools.
  working,

  /// Waiting on a human answer or approval.
  needsInput,

  /// Blocked for another reason a provider distinguishes from input.
  blocked,

  /// Completed background work that has not been reviewed yet.
  finished,

  /// Ready for input with nothing pending.
  idle,

  /// Present, but the provider cannot classify it confidently.
  unknown,
}

extension AgentAttentionStateDetails on AgentAttentionState {
  String get label => switch (this) {
    AgentAttentionState.working => 'Working',
    AgentAttentionState.needsInput => 'Needs input',
    AgentAttentionState.blocked => 'Blocked',
    AgentAttentionState.finished => 'Finished',
    AgentAttentionState.idle => 'Idle',
    AgentAttentionState.unknown => 'Unknown',
  };

  /// Whether this state means a human should look at the agent now.
  bool get needsAttention =>
      this == AgentAttentionState.needsInput ||
      this == AgentAttentionState.blocked;
}

/// One remote agent as reported by a provider.
class AgentInfo {
  const AgentInfo({
    required this.id,
    required this.name,
    required this.state,
    this.kind = '',
    this.workspace,
    this.tab,
    this.pane,
    this.stateChangedAt,
    this.stateSequence,
  });

  /// Stable identity across polls (provider-specific; e.g. pane id or a
  /// unique live agent name). Used to deduplicate notifications.
  final String id;

  /// Safe display label.
  final String name;

  final AgentAttentionState state;

  /// Provider-reported agent kind (e.g. which CLI runs in the pane).
  final String kind;

  final String? workspace;
  final String? tab;
  final String? pane;

  /// When the agent entered [state], if the provider reports it.
  final DateTime? stateChangedAt;

  /// Monotonic state-transition sequence, if the provider reports one.
  final int? stateSequence;

  @override
  bool operator ==(Object other) {
    return other is AgentInfo &&
        other.id == id &&
        other.name == name &&
        other.state == state &&
        other.kind == kind &&
        other.workspace == workspace &&
        other.tab == tab &&
        other.pane == pane &&
        other.stateChangedAt == stateChangedAt &&
        other.stateSequence == stateSequence;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    state,
    kind,
    workspace,
    tab,
    pane,
    stateChangedAt,
    stateSequence,
  );
}

/// One poll's worth of agent information for a host.
class AgentAttentionSnapshot {
  const AgentAttentionSnapshot({required this.agents});

  final List<AgentInfo> agents;
}

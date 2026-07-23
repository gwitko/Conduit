import 'package:conduit/features/agent_attention/domain/agent_attention.dart';
import 'package:conduit/features/agent_attention/domain/agent_command_runner.dart';

/// Thrown when a provider's tooling is missing or too old on the host —
/// a terminal condition for monitoring (until the session reconnects),
/// unlike transient fetch errors.
class AgentProviderUnavailable implements Exception {
  const AgentProviderUnavailable(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Reads agent state from one remote agent/session manager.
///
/// Implementations must use the manager's machine-readable interface, parse
/// defensively (older versions, partial output), and never scrape terminal
/// contents.
abstract class AgentAttentionProvider {
  /// Stable identifier, e.g. `herdr`.
  String get id;

  /// Human-readable name shown in UI, e.g. `Herdr`.
  String get label;

  Future<AgentAttentionSnapshot> fetchAgents(AgentCommandRunner runner);

  /// Command that focuses [agent] in the remote manager's UI, or null when
  /// the provider has no such command.
  String? focusCommand(AgentInfo agent);
}

/// Result of one non-interactive remote command.
class AgentCommandResult {
  const AgentCommandResult({
    required this.stdout,
    required this.stderr,
    this.exitCode,
  });

  final String stdout;
  final String stderr;

  /// Null when the remote side reported no exit status.
  final int? exitCode;
}

/// Runs short non-interactive commands on a host, independent of the
/// interactive terminal PTY, so polling never types into the user's session.
abstract class AgentCommandRunner {
  Future<AgentCommandResult> run(String command, {required Duration timeout});

  /// Closes any underlying connection. The runner must not be used after.
  Future<void> close();
}

/// Posts local "agent needs attention" notifications.
///
/// Content passed here must already be lock-screen safe: agent labels and
/// host names only — never prompt contents, terminal output, or paths.
abstract class AgentAttentionNotifier {
  /// Shows (or replaces, for the same [id]) one notification.
  Future<void> show({
    required String id,
    required String title,
    required String body,
  });
}

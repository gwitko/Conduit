import 'package:conduit/features/agent_attention/domain/agent_attention_notifier.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android implementation of agent notifications over a platform channel,
/// following the app's native-notification precedent (the background
/// keepalive service). Notification permission rides the existing
/// POST_NOTIFICATIONS request flow in `main.dart`.
///
/// On platforms without a native handler (currently iOS) `show` is a no-op;
/// the dashboard itself works everywhere.
class PlatformAgentAttentionNotifier implements AgentAttentionNotifier {
  const PlatformAgentAttentionNotifier();

  static const _channel = MethodChannel('conduit/agent_notifications');

  @override
  Future<void> show({
    required String id,
    required String title,
    required String body,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('show', {
        'id': id,
        'title': title,
        'body': body,
      });
    } on MissingPluginException {
      // No native handler registered (e.g. tests); notifications are
      // best-effort.
    } on PlatformException {
      // Notification permission may be denied; never let that break polling.
    }
  }
}

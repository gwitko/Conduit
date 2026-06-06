import 'package:flutter/services.dart';

class TerminalBackgroundKeepalive {
  const TerminalBackgroundKeepalive();

  static const _channel = MethodChannel('conduit/background_keepalive');

  Future<void> start({required int sessionCount}) async {
    await _channel.invokeMethod<void>('start', {'sessionCount': sessionCount});
  }

  Future<void> stop() async {
    await _channel.invokeMethod<void>('stop');
  }

  Future<void> requestNotificationPermission() async {
    await _channel.invokeMethod<void>('requestNotificationPermission');
  }
}

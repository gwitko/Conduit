import 'dart:async';

class SecurityKeyInteraction {
  SecurityKeyInteraction._();

  static final instance = SecurityKeyInteraction._();

  final _messages = StreamController<String>.broadcast();

  Stream<String> get messages => _messages.stream;

  void announce(String message) {
    if (!_messages.isClosed) {
      _messages.add(message);
    }
  }
}

import 'dart:async';

typedef SecurityKeyPinPrompt =
    Future<String?> Function(SecurityKeyPinRequest request);

typedef SecurityKeySelectionPrompt =
    Future<int?> Function(SecurityKeySelectionRequest request);

class SecurityKeyPinRequest {
  const SecurityKeyPinRequest({this.retriesRemaining});

  final int? retriesRemaining;
}

class SecurityKeySelectionRequest {
  const SecurityKeySelectionRequest({required this.labels});

  final List<String> labels;
}

class SecurityKeySelection {
  const SecurityKeySelection(this.index);

  final int? index;
}

class SecurityKeyInteraction {
  SecurityKeyInteraction._();

  static final instance = SecurityKeyInteraction._();

  final _messages = StreamController<String>.broadcast();
  final _pinPrompts = <SecurityKeyPinPrompt>[];
  final _selectionPrompts = <SecurityKeySelectionPrompt>[];

  Stream<String> get messages => _messages.stream;

  void announce(String message) {
    if (!_messages.isClosed) {
      _messages.add(message);
    }
  }

  void registerPinPrompt(SecurityKeyPinPrompt prompt) {
    _pinPrompts.add(prompt);
  }

  void unregisterPinPrompt(SecurityKeyPinPrompt prompt) {
    _pinPrompts.remove(prompt);
  }

  Future<String?> requestPin({int? retriesRemaining}) {
    if (_pinPrompts.isEmpty) {
      return Future<String?>.value();
    }
    return _pinPrompts.last(
      SecurityKeyPinRequest(retriesRemaining: retriesRemaining),
    );
  }

  void registerSelectionPrompt(SecurityKeySelectionPrompt prompt) {
    _selectionPrompts.add(prompt);
  }

  void unregisterSelectionPrompt(SecurityKeySelectionPrompt prompt) {
    _selectionPrompts.remove(prompt);
  }

  Future<SecurityKeySelection?> requestKeySelection(List<String> labels) async {
    if (_selectionPrompts.isEmpty) {
      return null;
    }
    final index = await _selectionPrompts.last(
      SecurityKeySelectionRequest(labels: labels),
    );
    return SecurityKeySelection(index);
  }
}

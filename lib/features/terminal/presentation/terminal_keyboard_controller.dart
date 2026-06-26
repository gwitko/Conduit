import 'package:conduit_vt/conduit_vt.dart';
import 'package:flutter/foundation.dart';

class TerminalKeyboardController extends TerminalInputHandler
    with ChangeNotifier {
  TerminalKeyboardController(this._delegate);

  final TerminalInputHandler _delegate;

  bool _ctrl = false;
  bool _alt = false;

  bool get ctrl => _ctrl;
  bool get alt => _alt;

  set ctrl(bool value) {
    if (_ctrl == value) {
      return;
    }
    _ctrl = value;
    notifyListeners();
  }

  set alt(bool value) {
    if (_alt == value) {
      return;
    }
    _alt = value;
    notifyListeners();
  }

  void clearModifiers() {
    if (!_ctrl && !_alt) {
      return;
    }
    _ctrl = false;
    _alt = false;
    notifyListeners();
  }

  @override
  String? call(TerminalKeyboardEvent event) {
    final usesToggledModifier = _ctrl || _alt;
    final result = _delegate.call(
      event.copyWith(ctrl: event.ctrl || _ctrl, alt: event.alt || _alt),
    );
    if (usesToggledModifier) {
      clearModifiers();
    }
    return result;
  }
}

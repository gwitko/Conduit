class TerminalStringSequenceFilter {
  static const Set<int> _introducers = {0x50, 0x58, 0x5e, 0x5f};
  static const int _esc = 0x1b;
  static const int _st8bit = 0x9c;
  static const int _stFinal = 0x5c;

  _FilterState _state = _FilterState.normal;

  void reset() => _state = _FilterState.normal;

  String process(String chunk) {
    final out = StringBuffer();
    for (final code in chunk.codeUnits) {
      switch (_state) {
        case _FilterState.normal:
          if (code == _esc) {
            _state = _FilterState.sawEsc;
          } else {
            out.writeCharCode(code);
          }
        case _FilterState.sawEsc:
          if (_introducers.contains(code)) {
            _state = _FilterState.stripping;
          } else {
            out.writeCharCode(_esc);
            if (code == _esc) {
              _state = _FilterState.sawEsc;
            } else {
              out.writeCharCode(code);
              _state = _FilterState.normal;
            }
          }
        case _FilterState.stripping:
          if (code == _esc) {
            _state = _FilterState.strippingSawEsc;
          } else if (code == _st8bit) {
            _state = _FilterState.normal;
          }
        case _FilterState.strippingSawEsc:
          if (code == _stFinal) {
            _state = _FilterState.normal;
          } else if (code != _esc) {
            _state = _FilterState.stripping;
          }
      }
    }
    return out.toString();
  }
}

enum _FilterState { normal, sawEsc, stripping, strippingSawEsc }

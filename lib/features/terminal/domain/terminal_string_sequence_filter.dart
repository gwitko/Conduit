/// Removes terminal "string" control sequences that the embedded emulator
/// (xterm) does not consume — DCS, SOS, PM and APC — so their payloads don't
/// leak onto the screen as literal text.
///
/// The motivating case: vim/neovim probe terminal capabilities with a DCS
/// XTGETTCAP query (`ESC P + q <hex> ESC \`, e.g. `+q4D73` for the `Ms`
/// clipboard cap). xterm 4.x doesn't handle DCS, so without this the `+q4D73`
/// payload paints into the buffer. Stripping these is safe: xterm can't act on
/// them regardless, and OSC (titles), CSI and plain escapes are left untouched.
///
/// The filter is stateful so it works across chunk boundaries.
class TerminalStringSequenceFilter {
  // DCS, SOS, PM, APC introducers following ESC: P, X, ^, _.
  static const Set<int> _introducers = {0x50, 0x58, 0x5e, 0x5f};
  static const int _esc = 0x1b;
  static const int _st8bit = 0x9c; // single-byte String Terminator
  static const int _stFinal = 0x5c; // '\' completing ESC \\

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

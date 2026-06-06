/// A single predicted character drawn as a tentative overlay on top of the
/// terminal. Predictions never touch the real terminal buffer, so a wrong
/// prediction can only ever show a transient glyph — it cannot corrupt the
/// authoritative screen the server owns.
class TerminalPrediction {
  const TerminalPrediction({
    required this.row,
    required this.column,
    required this.character,
    required this.inputNum,
  });

  /// Viewport row (0 = top of the visible screen).
  final int row;

  /// Column within the row.
  final int column;

  /// The single predicted grapheme.
  final String character;

  /// The input-state number this prediction belongs to (from
  /// `MoshSession.send`). Used to cull it once the server confirms that input.
  final int inputNum;
}

/// Conservative local-echo predictor for high-latency sessions.
///
/// It predicts only the common, safe case — plain printable characters typed at
/// the cursor on the main screen — and freezes (stops predicting) the moment
/// anything ambiguous happens: a control key, an escape sequence, the alternate
/// screen (full-screen apps like vim), or the line wrapping. Predictions are
/// culled when the server acknowledges the corresponding input
/// (`recordEchoAck`), at which point the real server content has caught up.
///
/// Display is gated on round-trip time: predictions are only surfaced when the
/// link is laggy enough for local echo to actually help.
class PredictiveEcho {
  PredictiveEcho({this.displayThreshold = const Duration(milliseconds: 60)});

  /// Predictions are only shown when the smoothed RTT is at least this high.
  final Duration displayThreshold;

  final List<TerminalPrediction> _predictions = <TerminalPrediction>[];
  Duration? _srtt;
  int? _anchorRow;
  int? _nextColumn;
  bool _frozen = false;

  void updateSrtt(Duration? srtt) {
    _srtt = srtt;
  }

  /// Record locally-typed input. [inputNum] is the input-state number the
  /// transport assigned to this data. [cursorRow]/[cursorColumn] are the
  /// terminal cursor position (viewport-relative) at send time, [viewWidth] the
  /// column count, and [altScreen] whether a full-screen app is active.
  void recordInput(
    String data, {
    required int inputNum,
    required int cursorRow,
    required int cursorColumn,
    required int viewWidth,
    required bool altScreen,
  }) {
    if (altScreen || data.isEmpty) {
      _freeze();
      return;
    }

    for (final rune in data.runes) {
      if (!_isPrintable(rune) || _frozen) {
        _freeze();
        return;
      }

      _anchorRow ??= cursorRow;
      _nextColumn ??= cursorColumn;

      if (_nextColumn! >= viewWidth) {
        // Don't predict across a line wrap; let the server resolve it.
        _freeze();
        return;
      }

      _predictions.add(
        TerminalPrediction(
          row: _anchorRow!,
          column: _nextColumn!,
          character: String.fromCharCode(rune),
          inputNum: inputNum,
        ),
      );
      _nextColumn = _nextColumn! + 1;
    }
  }

  /// The server has incorporated all input up to and including [ackNum]; those
  /// predictions are now reflected in real content and can be dropped.
  void recordEchoAck(int ackNum) {
    _predictions.removeWhere((p) => p.inputNum <= ackNum);
    if (_predictions.isEmpty) {
      _anchorRow = null;
      _nextColumn = null;
      _frozen = false;
    }
  }

  /// Clear all prediction state (on connect, resize, or screen switch).
  void reset() {
    _predictions.clear();
    _anchorRow = null;
    _nextColumn = null;
    _frozen = false;
  }

  /// Predicted cells to draw, or empty when the link isn't laggy enough to
  /// warrant showing predictions.
  List<TerminalPrediction> get overlay {
    final srtt = _srtt;
    if (srtt == null || srtt < displayThreshold) {
      return const <TerminalPrediction>[];
    }
    return List<TerminalPrediction>.unmodifiable(_predictions);
  }

  bool get hasPredictions => _predictions.isNotEmpty;

  void _freeze() {
    _frozen = true;
  }

  static bool _isPrintable(int rune) {
    if (rune == 0x7f) return false;
    if (rune < 0x20) return false;
    if (rune >= 0x80 && rune < 0xa0) return false;
    return true;
  }
}

class TerminalPrediction {
  const TerminalPrediction({
    required this.row,
    required this.column,
    required this.character,
    required this.inputNum,
  });

  final int row;

  final int column;

  final String character;

  final int inputNum;
}

class PredictiveEcho {
  PredictiveEcho({this.displayThreshold = const Duration(milliseconds: 60)});

  final Duration displayThreshold;

  final List<TerminalPrediction> _predictions = <TerminalPrediction>[];
  Duration? _srtt;
  int? _anchorRow;
  int? _nextColumn;
  bool _frozen = false;

  void updateSrtt(Duration? srtt) {
    _srtt = srtt;
  }

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

  void recordEchoAck(int ackNum) {
    _predictions.removeWhere((p) => p.inputNum <= ackNum);
    if (_predictions.isEmpty) {
      _anchorRow = null;
      _nextColumn = null;
      _frozen = false;
    }
  }

  void reset() {
    _predictions.clear();
    _anchorRow = null;
    _nextColumn = null;
    _frozen = false;
  }

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

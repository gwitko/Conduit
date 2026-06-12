class TerminalPrediction {
  const TerminalPrediction({
    required this.row,
    required this.column,
    required this.character,
    required this.inputNum,
    this.erase = false,
  });

  final int row;

  final int column;

  final String character;

  final int inputNum;

  final bool erase;
}

class PredictiveEcho {
  final List<TerminalPrediction> _predictions = <TerminalPrediction>[];
  int? _anchorRow;
  int? _nextColumn;
  int? _lineStartRow;
  int? _lineStartColumn;
  bool _frozen = false;

  void updateSrtt(Duration? _) {}

  void recordInput(
    String data, {
    int inputNum = 0,
    required int cursorRow,
    required int cursorColumn,
    required int viewWidth,
    required bool altScreen,
  }) {
    if (altScreen || data.isEmpty) {
      _freeze();
      return;
    }

    if (_frozen && _canStartAfterFreeze(data)) {
      reset();
    }

    for (final rune in data.runes) {
      _anchorRow ??= cursorRow;
      _nextColumn ??= cursorColumn;
      _lineStartRow ??= cursorRow;
      _lineStartColumn ??= cursorColumn;

      if (_isBackspace(rune)) {
        if (!_recordBackspace(inputNum)) return;
        continue;
      }

      if (!_isPrintable(rune) || _frozen) {
        _freeze();
        return;
      }

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

  void recordEchoAck(int _) {}

  void removeWhere(bool Function(TerminalPrediction prediction) test) {
    _predictions.removeWhere(test);
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
    _lineStartRow = null;
    _lineStartColumn = null;
    _frozen = false;
  }

  List<TerminalPrediction> get overlay {
    return List<TerminalPrediction>.unmodifiable(_predictions);
  }

  bool get hasPredictions => _predictions.isNotEmpty;

  void _freeze() {
    _frozen = true;
    _lineStartRow = null;
    _lineStartColumn = null;
  }

  bool _canStartAfterFreeze(String data) {
    if (data.isEmpty) {
      return false;
    }
    final first = data.runes.first;
    return _isPrintable(first) || _isBackspace(first);
  }

  bool _recordBackspace(int inputNum) {
    if (_frozen) {
      return false;
    }
    final nextColumn = _nextColumn;
    final anchorRow = _anchorRow;
    final lineStartColumn = _lineStartColumn;
    if (nextColumn == null ||
        anchorRow == null ||
        lineStartColumn == null ||
        nextColumn <= 0) {
      _freeze();
      return false;
    }

    final erasedColumn = nextColumn - 1;
    if (erasedColumn < lineStartColumn || anchorRow != _lineStartRow) {
      _freeze();
      return false;
    }
    final pendingIndex = _predictions.lastIndexWhere(
      (prediction) =>
          prediction.row == anchorRow && prediction.column == erasedColumn,
    );
    if (pendingIndex >= 0) {
      _predictions.removeAt(pendingIndex);
    } else {
      _predictions.add(
        TerminalPrediction(
          row: anchorRow,
          column: erasedColumn,
          character: '',
          inputNum: inputNum,
          erase: true,
        ),
      );
    }

    _nextColumn = erasedColumn;
    if (_predictions.isEmpty) {
      _anchorRow = null;
      _nextColumn = null;
    }
    return true;
  }

  static bool _isBackspace(int rune) {
    return rune == 0x08 || rune == 0x7f;
  }

  static bool _isPrintable(int rune) {
    if (rune == 0x7f) return false;
    if (rune < 0x20) return false;
    if (rune >= 0x80 && rune < 0xa0) return false;
    return true;
  }
}

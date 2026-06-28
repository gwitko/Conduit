import 'dart:async';
import 'dart:convert';

import 'package:conduit/core/app_failure.dart';
import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:conduit/features/terminal/domain/network_connectivity.dart';
import 'package:conduit/features/terminal/domain/predictive_echo.dart';
import 'package:conduit/features/terminal/domain/predictive_terminal_session.dart';
import 'package:conduit/features/terminal/domain/roaming_terminal_session.dart';
import 'package:conduit/features/terminal/domain/security_key_interaction.dart';
import 'package:conduit/features/terminal/domain/ssh_terminal_repository.dart';
import 'package:conduit/features/terminal/domain/ssh_terminal_session.dart';
import 'package:conduit/features/terminal/domain/terminal_string_sequence_filter.dart';
import 'package:conduit/features/terminal/presentation/terminal_keyboard_controller.dart';
import 'package:conduit_vt/conduit_vt.dart';
import 'package:flutter/foundation.dart';

enum TerminalConnectionStatus {
  idle,
  connecting,
  connected,
  disconnected,
  failed,
}

class TerminalSessionController extends ChangeNotifier {
  TerminalSessionController({
    required this.host,
    required this.repository,
    this.connectivity,
    bool predictiveEchoEnabled = false,
  }) : keyboard = TerminalKeyboardController(defaultInputHandler),
       terminal = Terminal(maxLines: 10000) {
    _predictiveEchoEnabled = predictiveEchoEnabled;
    _configureTerminal();
  }

  final SavedHost host;
  final SshTerminalRepository repository;
  final NetworkConnectivity? connectivity;
  final TerminalKeyboardController keyboard;
  final Terminal terminal;
  final _outputFilter = TerminalStringSequenceFilter();
  final _predictiveEcho = PredictiveEcho();
  final _terminalPaintNotifier = ChangeNotifier();
  final Stopwatch _inputClock = Stopwatch()..start();

  TerminalConnectionStatus _status = TerminalConnectionStatus.idle;
  SshTerminalSession? _session;
  StreamSubscription<String>? _stdoutSubscription;
  StreamSubscription<String>? _stderrSubscription;
  StreamSubscription<void>? _doneSubscription;
  StreamSubscription<void>? _connectivitySubscription;
  StreamSubscription<int>? _echoAckSubscription;
  int _pixelWidth = 0;
  int _pixelHeight = 0;
  Timer? _resizeTimer;
  int _pendingColumns = 0;
  int _pendingRows = 0;
  bool _disconnecting = false;
  bool _disposed = false;
  bool _predictiveEchoEnabled = false;
  int _connectionGeneration = 0;
  int? _lastIosEnterOutputMs;

  static const _iosDuplicateEnterWindow = Duration(milliseconds: 80);

  TerminalConnectionStatus get status => _status;
  String get title => host.name;
  bool get isConnected => _status == TerminalConnectionStatus.connected;
  bool get predictiveEchoEnabled => _predictiveEchoEnabled;
  Listenable get terminalPaintListenable => _terminalPaintNotifier;

  List<TerminalCellOverlay> get overlays {
    if (!_predictiveEchoEnabled) {
      return const <TerminalCellOverlay>[];
    }

    return [
      for (final prediction in _predictiveEcho.overlay)
        TerminalCellOverlay(
          row: prediction.row,
          column: prediction.column,
          text: prediction.character,
          opacity: prediction.erase ? 1 : 0.62,
          erase: prediction.erase,
        ),
    ];
  }

  set predictiveEchoEnabled(bool enabled) {
    if (_predictiveEchoEnabled == enabled) {
      return;
    }
    _predictiveEchoEnabled = enabled;
    if (!enabled) {
      _predictiveEcho.reset();
    }
    _notifyTerminalPaint();
    notifyListeners();
  }

  bool get shouldConnect =>
      !_disconnecting &&
      (_status == TerminalConnectionStatus.idle ||
          _status == TerminalConnectionStatus.disconnected ||
          _status == TerminalConnectionStatus.failed);

  Future<void> connect() async {
    if (_status == TerminalConnectionStatus.connecting ||
        _status == TerminalConnectionStatus.connected ||
        _disconnecting ||
        _disposed) {
      return;
    }

    final generation = ++_connectionGeneration;
    _outputFilter.reset();
    _predictiveEcho.reset();
    _status = TerminalConnectionStatus.connecting;
    terminal.write(
      host.isLocal
          ? 'Starting ${host.name}...\r\n'
          : 'Connecting to ${host.endpoint}...\r\n',
    );
    notifyListeners();

    StreamSubscription<String>? securityKeySubscription;
    try {
      securityKeySubscription = SecurityKeyInteraction.instance.messages.listen(
        (message) => terminal.write('$message\r\n'),
      );
      final session = await repository.connect(
        host,
        columns: terminal.viewWidth,
        rows: terminal.viewHeight,
      );
      if (_disposed || generation != _connectionGeneration || _disconnecting) {
        unawaited(session.close());
        return;
      }
      _session = session;

      terminal.buffer.clear();
      terminal.buffer.setCursor(0, 0);
      if (kDebugMode) {
        debugPrint(
          '[term ${host.name}] connect size -> '
          '${terminal.viewWidth}x${terminal.viewHeight}',
        );
      }
      session.resize(
        terminal.viewWidth,
        terminal.viewHeight,
        _pixelWidth,
        _pixelHeight,
      );

      _stdoutSubscription = session.stdout
          .cast<List<int>>()
          .transform(const Utf8Decoder(allowMalformed: true))
          .listen(
            (chunk) => _writeTerminalOutput(_outputFilter.process(chunk)),
            onError: _handleStreamError,
          );
      _stderrSubscription = session.stderr
          .cast<List<int>>()
          .transform(const Utf8Decoder(allowMalformed: true))
          .listen(_writeTerminalOutput, onError: _handleStreamError);
      _doneSubscription = session.done.asStream().listen((_) {
        if (_status == TerminalConnectionStatus.connected) {
          _status = TerminalConnectionStatus.disconnected;
          terminal.write(
            host.isLocal
                ? '\r\nShell exited.\r\n'
                : '\r\nConnection closed.\r\n',
          );
          notifyListeners();
        }
      }, onError: _handleStreamError);

      if (session is RoamingTerminalSession) {
        _connectivitySubscription = connectivity?.onNetworkChanged.listen(
          (_) => _rehome(),
        );
      }
      if (session is PredictiveTerminalSession) {
        final predictiveSession = session as PredictiveTerminalSession;
        _predictiveEcho.updateSrtt(predictiveSession.smoothedRtt);
        _echoAckSubscription = predictiveSession.echoAcks.listen((int ackNum) {
          _predictiveEcho
            ..updateSrtt(predictiveSession.smoothedRtt)
            ..recordEchoAck(ackNum);
          _notifyTerminalPaint();
        }, onError: _handleStreamError);
      }

      _status = TerminalConnectionStatus.connected;
      notifyListeners();
      _startTmuxIfConfigured(session);
    } on AppFailure catch (failure) {
      if (_disposed || generation != _connectionGeneration) {
        return;
      }
      _fail(failure.toString());
    } catch (error) {
      if (_disposed || generation != _connectionGeneration) {
        return;
      }
      _fail('Connection failed: $error');
    } finally {
      await securityKeySubscription?.cancel();
    }
  }

  Future<void> disconnect() async {
    if (_disconnecting ||
        _status == TerminalConnectionStatus.disconnected ||
        _status == TerminalConnectionStatus.idle) {
      return;
    }
    _disconnecting = true;
    _connectionGeneration += 1;

    _resizeTimer?.cancel();
    _resizeTimer = null;
    await _stdoutSubscription?.cancel();
    await _stderrSubscription?.cancel();
    await _doneSubscription?.cancel();
    await _connectivitySubscription?.cancel();
    await _echoAckSubscription?.cancel();
    _stdoutSubscription = null;
    _stderrSubscription = null;
    _doneSubscription = null;
    _connectivitySubscription = null;
    _echoAckSubscription = null;
    _predictiveEcho.reset();

    final session = _session;
    _session = null;
    try {
      await session?.close();
    } finally {
      keyboard.clearModifiers();
      _status = TerminalConnectionStatus.disconnected;
      if (!_disposed) {
        terminal.write('\r\nDisconnected.\r\n');
        notifyListeners();
      }
      _disconnecting = false;
    }
  }

  void sendKey(TerminalKey key) {
    terminal.keyInput(key, ctrl: keyboard.ctrl, alt: keyboard.alt);
    keyboard.clearModifiers();
  }

  void sendText(String text) {
    terminal.textInput(text);
    keyboard.clearModifiers();
  }

  void sendControl(TerminalKey key) {
    terminal.keyInput(key, ctrl: true);
    keyboard.clearModifiers();
  }

  void paste(String text) {
    terminal.paste(text);
    keyboard.clearModifiers();
  }

  void _startTmuxIfConfigured(SshTerminalSession session) {
    final command = _buildTmuxCommand();
    if (command == null) {
      return;
    }
    unawaited(
      session.send(utf8.encode(command)).catchError(_handleStreamError),
    );
  }

  @visibleForTesting
  String? buildTmuxCommandForTesting() => _buildTmuxCommand();

  String? _buildTmuxCommand() {
    if (!host.startTmuxOnConnect) {
      return null;
    }
    final sessionName = host.tmuxSessionName.trim().isEmpty
        ? defaultTmuxSessionName
        : host.tmuxSessionName.trim();
    final command = StringBuffer(
      'tmux new-session -A -s ${_shellQuote(sessionName)}',
    );
    final startDirectory = host.tmuxStartDirectory.trim();
    if (startDirectory.isNotEmpty) {
      command.write(' -c ${_shellQuote(startDirectory)}');
    }
    command.write('\r');
    return command.toString();
  }

  static final _unquotedPath = RegExp(r'^[A-Za-z0-9_~./:=+-]+$');

  static String _shellQuote(String value) => _unquotedPath.hasMatch(value)
      ? value
      : "'${value.replaceAll("'", r"'\''")}'";

  void _configureTerminal() {
    terminal.inputHandler = keyboard;
    terminal.onResize = (columns, rows, pixelWidth, pixelHeight) {
      _pixelWidth = pixelWidth;
      _pixelHeight = pixelHeight;
      _pendingColumns = columns;
      _pendingRows = rows;
      _resizeTimer?.cancel();
      _resizeTimer = Timer(const Duration(milliseconds: 250), _flushResize);
    };
    terminal.onOutput = _sendTerminalOutput;
  }

  void _sendTerminalOutput(String data) {
    if (_shouldSuppressDuplicateIosEnter(data)) {
      return;
    }

    final session = _session;
    if (session == null) {
      return;
    }

    final bytes = utf8.encode(data);
    if (_predictiveEchoEnabled && session is PredictiveTerminalSession) {
      final predictiveSession = session as PredictiveTerminalSession;
      try {
        final inputNum = predictiveSession.sendWithInputState(bytes);
        _predictiveEcho
          ..updateSrtt(predictiveSession.smoothedRtt)
          ..recordInput(
            data,
            inputNum: inputNum,
            cursorRow: terminal.absoluteCursorRow,
            cursorColumn: terminal.cursorColumn,
            viewWidth: terminal.viewWidth,
            altScreen: terminal.isUsingAltBuffer,
          );
        _notifyTerminalPaint();
      } catch (error, stackTrace) {
        _handleStreamError(error, stackTrace);
      }
      return;
    }

    unawaited(session.send(bytes).catchError(_handleStreamError));
  }

  bool _shouldSuppressDuplicateIosEnter(String data) {
    if (defaultTargetPlatform != TargetPlatform.iOS || !_isEnterOutput(data)) {
      if (data.isNotEmpty && !_isEnterOutput(data)) {
        _lastIosEnterOutputMs = null;
      }
      return false;
    }

    final now = _inputClock.elapsedMilliseconds;
    final last = _lastIosEnterOutputMs;
    _lastIosEnterOutputMs = now;

    return last != null &&
        now - last <= _iosDuplicateEnterWindow.inMilliseconds;
  }

  bool _isEnterOutput(String data) {
    return data == '\r' || data == '\n' || data == '\r\n';
  }

  void _writeTerminalOutput(String data) {
    terminal.write(data);
    if (_predictiveEcho.hasPredictions) {
      _predictiveEcho.removeWhere(_isConfirmedPrediction);
      _notifyTerminalPaint();
    }
  }

  void _notifyTerminalPaint() {
    _terminalPaintNotifier.notifyListeners();
  }

  bool _isConfirmedPrediction(TerminalPrediction prediction) {
    if (prediction.erase) {
      return !_hasTerminalContentAt(prediction.row, prediction.column);
    }
    return _terminalCharacterAt(prediction.row, prediction.column) ==
            prediction.character ||
        _terminalCursorPassed(prediction.row, prediction.column);
  }

  bool _hasTerminalContentAt(int row, int column) {
    return _terminalCharacterAt(row, column) != null;
  }

  String? _terminalCharacterAt(int row, int column) {
    if (row < 0 || row >= terminal.buffer.lines.length) {
      return null;
    }
    final line = terminal.buffer.lines[row];
    if (column < 0 || column >= line.length) {
      return null;
    }
    final codePoint = line.getCodePoint(column);
    return codePoint == 0 ? null : String.fromCharCode(codePoint);
  }

  bool _terminalCursorPassed(int row, int column) {
    final cursorRow = terminal.absoluteCursorRow;
    if (row < cursorRow) {
      return true;
    }
    return row == cursorRow && column < terminal.cursorColumn;
  }

  void _rehome() {
    final session = _session;
    if (session is! RoamingTerminalSession ||
        _status != TerminalConnectionStatus.connected) {
      return;
    }
    final roaming = session as RoamingTerminalSession;
    unawaited(roaming.rehome().catchError(_handleStreamError));
  }

  void forceResize() {
    if (_session == null || _status != TerminalConnectionStatus.connected) return;
    _pendingColumns = terminal.viewWidth;
    _pendingRows = terminal.viewHeight;
    _resizeTimer?.cancel();
    _flushResize();
  }

  void _flushResize() {
    final session = _session;
    if (session == null) return;
    if (kDebugMode) {
      debugPrint(
        '[term ${host.name}] -> server ${_pendingColumns}x$_pendingRows',
      );
    }
    session.resize(_pendingColumns, _pendingRows, _pixelWidth, _pixelHeight);
  }

  void _handleStreamError(Object error, [StackTrace? stackTrace]) {
    if (_disposed || _status != TerminalConnectionStatus.connected) {
      return;
    }
    terminal.write('\r\n$error\r\n');
    _status = TerminalConnectionStatus.failed;
    notifyListeners();
  }

  void _fail(String message) {
    if (_disposed) {
      return;
    }
    _status = TerminalConnectionStatus.failed;
    terminal.write('\r\n$message\r\n');
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _connectionGeneration += 1;
    _resizeTimer?.cancel();
    unawaited(_stdoutSubscription?.cancel());
    unawaited(_stderrSubscription?.cancel());
    unawaited(_doneSubscription?.cancel());
    unawaited(_connectivitySubscription?.cancel());
    unawaited(_echoAckSubscription?.cancel());
    final session = _session;
    _session = null;
    if (session != null) {
      unawaited(session.close());
    }
    keyboard.dispose();
    _terminalPaintNotifier.dispose();
    super.dispose();
  }
}

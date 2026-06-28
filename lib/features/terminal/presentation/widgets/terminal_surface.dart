import 'package:conduit/core/theme/app_palette.dart';
import 'package:conduit/features/terminal/presentation/terminal_session_controller.dart';
import 'package:conduit_vt/conduit_vt.dart';
import 'package:flutter/material.dart';

class TerminalSurface extends StatefulWidget {
  const TerminalSurface({
    required this.session,
    required this.palette,
    required this.brightness,
    required this.fontFamily,
    required this.fontSize,
    required this.onFontSizeChanged,
    required this.predictiveEchoEnabled,
    required this.focusNode,
    required this.tmuxScrollMode,
    required this.onExitTmuxScrollMode,
    super.key,
  });

  final TerminalSessionController session;
  final AppPalette palette;
  final Brightness brightness;
  final String fontFamily;
  final double fontSize;
  final ValueChanged<double> onFontSizeChanged;
  final bool predictiveEchoEnabled;
  final FocusNode? focusNode;
  final bool tmuxScrollMode;
  final VoidCallback onExitTmuxScrollMode;

  @override
  State<TerminalSurface> createState() => _TerminalSurfaceState();
}

class _TerminalSurfaceState extends State<TerminalSurface> {
  final _pinchPointers = <int, Offset>{};
  double? _pinchStartDistance;
  double? _pinchStartFontSize;
  double _tmuxScrollDelta = 0;

  @override
  void initState() {
    super.initState();
    widget.session.predictiveEchoEnabled = widget.predictiveEchoEnabled;
    WidgetsBinding.instance.addPostFrameCallback((_) => _connectIfNeeded());
  }

  @override
  void didUpdateWidget(covariant TerminalSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.predictiveEchoEnabled != widget.predictiveEchoEnabled ||
        oldWidget.session != widget.session) {
      widget.session.predictiveEchoEnabled = widget.predictiveEchoEnabled;
    }
    if (oldWidget.session != widget.session) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _connectIfNeeded());
    }
  }

  Future<void> _connectIfNeeded() async {
    if (!mounted || !widget.session.shouldConnect) return;
    await widget.session.connect();
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.tmuxScrollMode) {
      return;
    }
    _pinchPointers[event.pointer] = event.localPosition;
    if (_pinchPointers.length == 2) {
      _pinchStartDistance = _pinchDistance;
      _pinchStartFontSize = widget.fontSize;
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (widget.tmuxScrollMode) {
      return;
    }
    if (!_pinchPointers.containsKey(event.pointer)) {
      return;
    }
    _pinchPointers[event.pointer] = event.localPosition;
    final startDistance = _pinchStartDistance;
    final startFontSize = _pinchStartFontSize;
    if (_pinchPointers.length != 2 ||
        startDistance == null ||
        startDistance == 0 ||
        startFontSize == null) {
      return;
    }
    widget.onFontSizeChanged(startFontSize * (_pinchDistance / startDistance));
  }

  void _handlePointerEnd(PointerEvent event) {
    if (widget.tmuxScrollMode) {
      return;
    }
    _pinchPointers.remove(event.pointer);
    if (_pinchPointers.length < 2) {
      _pinchStartDistance = null;
      _pinchStartFontSize = null;
    }
  }

  void _handleTmuxScrollDrag(DragUpdateDetails details) {
    _tmuxScrollDelta += details.primaryDelta ?? 0;
    const step = 12.0;
    while (_tmuxScrollDelta.abs() >= step) {
      if (_tmuxScrollDelta > 0) {
        widget.session.sendKey(TerminalKey.arrowUp);
        _tmuxScrollDelta -= step;
      } else {
        widget.session.sendKey(TerminalKey.arrowDown);
        _tmuxScrollDelta += step;
      }
    }
  }

  void _handleTmuxScrollEnd(DragEndDetails details) {
    _tmuxScrollDelta = 0;
  }

  double get _pinchDistance {
    final points = _pinchPointers.values.take(2).toList();
    if (points.length < 2) {
      return 0;
    }
    return (points[0] - points[1]).distance;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _handlePointerDown,
        onPointerMove: _handlePointerMove,
        onPointerUp: _handlePointerEnd,
        onPointerCancel: _handlePointerEnd,
        child: Stack(
          children: [
            ListenableBuilder(
              listenable: widget.session.terminalPaintListenable,
              builder: (context, _) {
                final overlays = widget.session.overlays;
                return TerminalView(
                  widget.session.terminal,
                  focusNode: widget.focusNode,
                  autofocus: widget.focusNode != null,
                  deleteDetection: true,
                  keyboardType: TextInputType.visiblePassword,
                  theme: widget.palette.terminalThemeFor(widget.brightness),
                  overlays: overlays,
                  textStyle: TerminalStyle(
                    fontFamily: widget.fontFamily,
                    fontSize: widget.fontSize,
                  ),
                  padding: const EdgeInsets.fromLTRB(0, 6, 0, 4),
                  cursorType: overlays.isEmpty
                      ? TerminalCursorType.block
                      : TerminalCursorType.verticalBar,
                  alwaysShowCursor: true,
                  simulateScroll: !widget.tmuxScrollMode,
                );
              },
            ),
            if (widget.tmuxScrollMode)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onVerticalDragUpdate: _handleTmuxScrollDrag,
                  onVerticalDragEnd: _handleTmuxScrollEnd,
                  child: const SizedBox.expand(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

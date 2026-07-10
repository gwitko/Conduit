import 'dart:async';

import 'package:conduit/core/presentation/system_navigation_insets.dart';
import 'package:conduit/core/theme/app_palette.dart';
import 'package:conduit/core/theme/terminal_appearance.dart';
import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:conduit/features/snippets/domain/terminal_snippet.dart';
import 'package:conduit/features/terminal/presentation/terminal_session_controller.dart';
import 'package:conduit_vt/conduit_vt.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TerminalKeyboardBar extends StatelessWidget {
  const TerminalKeyboardBar({
    required this.controller,
    required this.focusNode,
    required this.palette,
    required this.brightness,
    required this.rows,
    required this.globalSnippets,
    required this.fullscreen,
    required this.onToggleFullscreen,
    this.composeActive = false,
    this.onToggleCompose,
    required this.onEnterTmuxScrollMode,
    required this.onExitTmuxScrollMode,
    required this.tmuxPrefixKey,
    required this.tmuxScrollMode,
    super.key,
  });

  final TerminalSessionController controller;
  final FocusNode focusNode;
  final AppPalette palette;
  final Brightness brightness;
  final List<TerminalKeyboardRow> rows;
  final List<TerminalSnippet> globalSnippets;
  final bool fullscreen;
  final VoidCallback onToggleFullscreen;
  final bool composeActive;
  final VoidCallback? onToggleCompose;
  final VoidCallback onEnterTmuxScrollMode;
  final VoidCallback onExitTmuxScrollMode;
  final TmuxPrefixKey tmuxPrefixKey;
  final bool tmuxScrollMode;

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.paddingOf(context);
    return ListenableBuilder(
      listenable: controller.keyboard,
      builder: (context, _) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: palette.canvasFor(brightness),
            border: Border(
              top: BorderSide(color: palette.hairlineFor(brightness)),
            ),
          ),
          child: SafeArea(
            top: false,
            bottom: shouldApplyBottomSafeArea(context),
            left: false,
            right: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (index, row) in rows.indexed)
                  SizedBox(
                    height:
                        row.height -
                        (index == 0 ? 0 : 5) -
                        (index == rows.length - 1 ? 0 : 5),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.fromLTRB(
                        safePadding.left + 8,
                        index == 0 ? 7 : 2,
                        safePadding.right + 8,
                        index == rows.length - 1 ? 7 : 2,
                      ),
                      children: [
                        for (final item in row.items) _buildItem(item),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildItem(TerminalKeyboardItem item) {
    final action = item.action;
    if (item.kind == TerminalKeyboardItemKind.builtIn && action != null) {
      return _buildAction(action);
    }
    return _Key(
      label: item.displayLabel,
      palette: palette,
      brightness: brightness,
      onPressed: () => _triggerCustomItem(item),
    );
  }

  Widget _buildAction(TerminalKeyboardAction action) {
    return switch (action) {
      TerminalKeyboardAction.control => _ToggleKey(
        label: action.label,
        palette: palette,
        brightness: brightness,
        selected: controller.keyboard.ctrl,
        onPressed: () {
          controller.keyboard.ctrl = !controller.keyboard.ctrl;
          _focusTerminal();
        },
      ),
      TerminalKeyboardAction.alt => _ToggleKey(
        label: action.label,
        palette: palette,
        brightness: brightness,
        selected: controller.keyboard.alt,
        onPressed: () {
          controller.keyboard.alt = !controller.keyboard.alt;
          _focusTerminal();
        },
      ),
      TerminalKeyboardAction.compose => _ToggleKey(
        label: action.label,
        palette: palette,
        brightness: brightness,
        selected: composeActive,
        onPressed: () => onToggleCompose?.call(),
      ),
      TerminalKeyboardAction.fullscreen => _Key(
        icon: fullscreen
            ? Icons.fullscreen_exit_rounded
            : Icons.fullscreen_rounded,
        palette: palette,
        brightness: brightness,
        onPressed: () {
          onToggleFullscreen();
          _focusTerminal();
        },
      ),
      TerminalKeyboardAction.arrowUp => _Key(
        icon: Icons.keyboard_arrow_up_rounded,
        palette: palette,
        brightness: brightness,
        repeat: true,
        onPressed: () => _sendKey(TerminalKey.arrowUp),
      ),
      TerminalKeyboardAction.arrowDown => _Key(
        icon: Icons.keyboard_arrow_down_rounded,
        palette: palette,
        brightness: brightness,
        repeat: true,
        onPressed: () => _sendKey(TerminalKey.arrowDown),
      ),
      TerminalKeyboardAction.arrowLeft => _Key(
        icon: Icons.keyboard_arrow_left_rounded,
        palette: palette,
        brightness: brightness,
        repeat: true,
        onPressed: () => _sendKey(TerminalKey.arrowLeft),
      ),
      TerminalKeyboardAction.arrowRight => _Key(
        icon: Icons.keyboard_arrow_right_rounded,
        palette: palette,
        brightness: brightness,
        repeat: true,
        onPressed: () => _sendKey(TerminalKey.arrowRight),
      ),
      TerminalKeyboardAction.paste => _Key(
        icon: Icons.content_paste_rounded,
        palette: palette,
        brightness: brightness,
        onPressed: _paste,
      ),
      TerminalKeyboardAction.functionKeys => _MenuKey<TerminalKey>(
        label: 'Fn',
        tooltip: 'Function keys',
        palette: palette,
        brightness: brightness,
        onSelected: _sendKey,
        items: [
          for (final item in _functionKeys)
            PopupMenuItem(value: item.key, child: Text(item.label)),
        ],
      ),
      TerminalKeyboardAction.tmuxPrefix => _Key(
        label: action.label,
        palette: palette,
        brightness: brightness,
        onPressed: _sendTmuxPrefix,
      ),
      TerminalKeyboardAction.tmuxScrollback => _Key(
        label: action.label,
        palette: palette,
        brightness: brightness,
        selected: tmuxScrollMode,
        onPressed: _toggleTmuxScrollMode,
      ),
      TerminalKeyboardAction.tmuxMenu => _MenuKey<_TmuxAction>(
        label: 'Tmux+',
        tooltip: 'Tmux actions',
        palette: palette,
        brightness: brightness,
        onSelected: _triggerTmuxAction,
        items: [
          for (final action in _TmuxAction.values)
            PopupMenuItem(
              value: action,
              child: Row(
                children: [
                  Icon(action.icon, size: 18),
                  const SizedBox(width: 10),
                  Text(action.label),
                ],
              ),
            ),
        ],
      ),
      TerminalKeyboardAction.snippets => _MenuKey<_SnippetMenuItem>(
        label: action.label,
        tooltip: 'Snippets',
        palette: palette,
        brightness: brightness,
        onSelected: _triggerSnippetMenuItem,
        items: _snippetMenuItems(),
      ),
      _ => _Key(
        label: action.label,
        palette: palette,
        brightness: brightness,
        repeat: _repeatableActions.contains(action),
        onPressed: () => _triggerAction(action),
      ),
    };
  }

  void _triggerAction(TerminalKeyboardAction action) {
    switch (action) {
      case TerminalKeyboardAction.escape:
        _sendKey(TerminalKey.escape);
      case TerminalKeyboardAction.tab:
        _sendKey(TerminalKey.tab);
      case TerminalKeyboardAction.home:
        _sendKey(TerminalKey.home);
      case TerminalKeyboardAction.end:
        _sendKey(TerminalKey.end);
      case TerminalKeyboardAction.pageUp:
        _sendKey(TerminalKey.pageUp);
      case TerminalKeyboardAction.pageDown:
        _sendKey(TerminalKey.pageDown);
      case TerminalKeyboardAction.controlC:
        _sendControl(TerminalKey.keyC);
      case TerminalKeyboardAction.controlD:
        _sendControl(TerminalKey.keyD);
      case TerminalKeyboardAction.controlZ:
        _sendControl(TerminalKey.keyZ);
      case TerminalKeyboardAction.controlL:
        _sendControl(TerminalKey.keyL);
      case TerminalKeyboardAction.colon:
        _sendText(':');
      case TerminalKeyboardAction.slash:
        _sendText('/');
      case TerminalKeyboardAction.pipe:
        _sendText('|');
      case TerminalKeyboardAction.dash:
        _sendText('-');
      case TerminalKeyboardAction.control:
      case TerminalKeyboardAction.alt:
      case TerminalKeyboardAction.fullscreen:
      case TerminalKeyboardAction.arrowUp:
      case TerminalKeyboardAction.arrowDown:
      case TerminalKeyboardAction.arrowLeft:
      case TerminalKeyboardAction.arrowRight:
      case TerminalKeyboardAction.paste:
      case TerminalKeyboardAction.functionKeys:
      case TerminalKeyboardAction.tmuxPrefix:
      case TerminalKeyboardAction.tmuxScrollback:
      case TerminalKeyboardAction.tmuxMenu:
      case TerminalKeyboardAction.snippets:
      case TerminalKeyboardAction.compose:
        break;
    }
  }

  List<PopupMenuEntry<_SnippetMenuItem>> _snippetMenuItems() {
    final entries = <PopupMenuEntry<_SnippetMenuItem>>[];
    void addSnippetGroup(String label, List<TerminalSnippet> snippets) {
      final valid = snippets.where((snippet) => snippet.isValid).toList();
      if (valid.isEmpty) {
        return;
      }
      if (entries.isNotEmpty) {
        entries.add(const PopupMenuDivider(height: 8));
      }
      entries.add(PopupMenuItem(enabled: false, child: Text(label)));
      for (final snippet in valid) {
        entries.add(
          PopupMenuItem(
            value: _SnippetMenuItem.snippet(snippet),
            child: _SnippetMenuRow(snippet: snippet),
          ),
        );
      }
    }

    addSnippetGroup('Host', controller.host.snippets);
    addSnippetGroup('Global', globalSnippets);
    if (controller.host.password.isNotEmpty) {
      if (entries.isNotEmpty) {
        entries.add(const PopupMenuDivider(height: 8));
      }
      entries.add(
        PopupMenuItem(
          value: _SnippetMenuItem.password(controller.host.password),
          child: const _SnippetMenuRow(
            snippet: TerminalSnippet(
              id: 'host-password',
              label: 'Password',
              text: '',
              hidden: true,
              submit: false,
            ),
          ),
        ),
      );
    }

    if (entries.isEmpty) {
      entries.add(
        const PopupMenuItem(enabled: false, child: Text('No snippets saved')),
      );
    }
    return entries;
  }

  void _triggerSnippetMenuItem(_SnippetMenuItem item) {
    switch (item) {
      case _SnippetMenuSnippet(:final snippet):
        _sendSnippet(snippet);
      case _SnippetMenuPassword(:final password):
        _sendText(password);
    }
  }

  void _sendSnippet(TerminalSnippet snippet) {
    final text = snippet.submit ? '${snippet.text}\r' : snippet.text;
    if (text.isNotEmpty) {
      _sendText(text);
    } else {
      _focusTerminal();
    }
  }

  void _triggerTmuxAction(_TmuxAction action) {
    _sendTmuxPrefix();
    final key = action.key;
    if (key != null) {
      controller.sendKey(key);
    } else if (action.text != null) {
      controller.sendText(action.text!);
    }
    if (action.entersScrollMode) {
      onEnterTmuxScrollMode();
    }
    _focusTerminal();
  }

  void _toggleTmuxScrollMode() {
    if (tmuxScrollMode) {
      controller.sendText('q');
      onExitTmuxScrollMode();
      _focusTerminal();
      return;
    }
    _triggerTmuxAction(_TmuxAction.copyMode);
  }

  void _triggerCustomItem(TerminalKeyboardItem item) {
    switch (item.kind) {
      case TerminalKeyboardItemKind.customText:
        final text = item.submit ? '${item.text ?? ''}\r' : item.text;
        if (text != null && text.isNotEmpty) {
          _sendText(text);
        } else {
          _focusTerminal();
        }
      case TerminalKeyboardItemKind.customControl:
        final key = _controlKeyFor(item.controlKey);
        if (key != null) {
          _sendControl(key);
        } else {
          _focusTerminal();
        }
      case TerminalKeyboardItemKind.builtIn:
        final action = item.action;
        if (action != null) {
          _triggerAction(action);
        }
    }
  }

  void _sendKey(TerminalKey key) {
    controller.sendKey(key);
    _focusTerminal();
  }

  void _sendControl(TerminalKey key) {
    controller.sendControl(key);
    _focusTerminal();
  }

  void _sendTmuxPrefix() {
    controller.sendControl(switch (tmuxPrefixKey) {
      TmuxPrefixKey.controlB => TerminalKey.keyB,
      TmuxPrefixKey.controlA => TerminalKey.keyA,
    });
    _focusTerminal();
  }

  void _sendText(String text) {
    controller.sendText(text);
    _focusTerminal();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text != null && text.isNotEmpty) {
      controller.paste(text);
    }
    _focusTerminal();
  }

  void _focusTerminal() {
    if (focusNode.canRequestFocus) {
      focusNode.requestFocus();
    }
  }
}

sealed class _SnippetMenuItem {
  const _SnippetMenuItem();

  factory _SnippetMenuItem.snippet(TerminalSnippet snippet) =
      _SnippetMenuSnippet;

  factory _SnippetMenuItem.password(String password) = _SnippetMenuPassword;
}

class _SnippetMenuSnippet extends _SnippetMenuItem {
  const _SnippetMenuSnippet(this.snippet);

  final TerminalSnippet snippet;
}

class _SnippetMenuPassword extends _SnippetMenuItem {
  const _SnippetMenuPassword(this.password);

  final String password;
}

class _SnippetMenuRow extends StatelessWidget {
  const _SnippetMenuRow({required this.snippet});

  final TerminalSnippet snippet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          snippet.hidden ? Icons.visibility_off_rounded : Icons.code_rounded,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(snippet.label, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (!snippet.hidden && snippet.text.isNotEmpty)
                Text(
                  snippet.submit ? '${snippet.text} + Enter' : snippet.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _TmuxAction {
  newWindow('New window', Icons.add_box_rounded, text: 'c'),
  previousWindow('Previous window', Icons.skip_previous_rounded, text: 'p'),
  nextWindow('Next window', Icons.skip_next_rounded, text: 'n'),
  windowList('Window list', Icons.view_list_rounded, text: 'w'),
  lastWindow('Last window', Icons.history_rounded, text: 'l'),
  renameWindow(
    'Rename window',
    Icons.drive_file_rename_outline_rounded,
    text: ',',
  ),
  splitHorizontal('Split horizontal', Icons.splitscreen_rounded, text: '"'),
  splitVertical('Split vertical', Icons.vertical_split_rounded, text: '%'),
  paneLeft(
    'Pane left',
    Icons.keyboard_arrow_left_rounded,
    key: TerminalKey.arrowLeft,
  ),
  paneRight(
    'Pane right',
    Icons.keyboard_arrow_right_rounded,
    key: TerminalKey.arrowRight,
  ),
  paneUp('Pane up', Icons.keyboard_arrow_up_rounded, key: TerminalKey.arrowUp),
  paneDown(
    'Pane down',
    Icons.keyboard_arrow_down_rounded,
    key: TerminalKey.arrowDown,
  ),
  zoomPane('Zoom pane', Icons.zoom_out_map_rounded, text: 'z'),
  commandPrompt(
    'Command prompt',
    Icons.keyboard_command_key_rounded,
    text: ':',
  ),
  copyMode(
    'Scrollback',
    Icons.swap_vert_rounded,
    text: '[',
    entersScrollMode: true,
  ),
  closePane('Close pane', Icons.close_fullscreen_rounded, text: 'x'),
  closeWindow('Close window', Icons.disabled_by_default_rounded, text: '&'),
  detach('Detach', Icons.logout_rounded, text: 'd');

  const _TmuxAction(
    this.label,
    this.icon, {
    this.text,
    this.key,
    this.entersScrollMode = false,
  });

  final String label;
  final IconData icon;
  final String? text;
  final TerminalKey? key;
  final bool entersScrollMode;
}

const _functionKeys = [
  (label: 'F1', key: TerminalKey.f1),
  (label: 'F2', key: TerminalKey.f2),
  (label: 'F3', key: TerminalKey.f3),
  (label: 'F4', key: TerminalKey.f4),
  (label: 'F5', key: TerminalKey.f5),
  (label: 'F6', key: TerminalKey.f6),
  (label: 'F7', key: TerminalKey.f7),
  (label: 'F8', key: TerminalKey.f8),
  (label: 'F9', key: TerminalKey.f9),
  (label: 'F10', key: TerminalKey.f10),
  (label: 'F11', key: TerminalKey.f11),
  (label: 'F12', key: TerminalKey.f12),
];

const _repeatInitialDelay = Duration(milliseconds: 250);
const _repeatInterval = Duration(milliseconds: 60);
const _repeatableActions = {
  TerminalKeyboardAction.home,
  TerminalKeyboardAction.end,
  TerminalKeyboardAction.pageUp,
  TerminalKeyboardAction.pageDown,
};
const _keyHeight = 36.0;
const _iconKeyMinWidth = 44.0;
const _textKeyMinWidth = 46.0;
const _textKeyHorizontalPadding = 10.0;

TerminalKey? _controlKeyFor(String? key) {
  return switch (key) {
    'A' => TerminalKey.keyA,
    'B' => TerminalKey.keyB,
    'C' => TerminalKey.keyC,
    'D' => TerminalKey.keyD,
    'E' => TerminalKey.keyE,
    'F' => TerminalKey.keyF,
    'G' => TerminalKey.keyG,
    'H' => TerminalKey.keyH,
    'I' => TerminalKey.keyI,
    'J' => TerminalKey.keyJ,
    'K' => TerminalKey.keyK,
    'L' => TerminalKey.keyL,
    'M' => TerminalKey.keyM,
    'N' => TerminalKey.keyN,
    'O' => TerminalKey.keyO,
    'P' => TerminalKey.keyP,
    'Q' => TerminalKey.keyQ,
    'R' => TerminalKey.keyR,
    'S' => TerminalKey.keyS,
    'T' => TerminalKey.keyT,
    'U' => TerminalKey.keyU,
    'V' => TerminalKey.keyV,
    'W' => TerminalKey.keyW,
    'X' => TerminalKey.keyX,
    'Y' => TerminalKey.keyY,
    'Z' => TerminalKey.keyZ,
    _ => null,
  };
}

class _Key extends StatelessWidget {
  const _Key({
    required this.palette,
    required this.brightness,
    this.onPressed,
    this.label,
    this.icon,
    this.repeat = false,
    this.selected = false,
  });

  final AppPalette palette;
  final Brightness brightness;
  final String? label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool repeat;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final isIconKey = icon != null;
    final enabled = onPressed != null;
    final foreground = enabled
        ? selected
              ? palette.accent
              : palette.foregroundFor(brightness)
        : palette.mutedForegroundFor(brightness);
    final background = selected
        ? Color.alphaBlend(
            palette.accent.withValues(alpha: 0.22),
            palette.panelFor(brightness),
          )
        : palette.panelFor(brightness);
    return _KeySurface(
      color: background,
      onPressed: onPressed,
      repeat: repeat,
      child: Container(
        height: _keyHeight,
        constraints: BoxConstraints(
          minWidth: isIconKey ? _iconKeyMinWidth : _textKeyMinWidth,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isIconKey ? 0 : _textKeyHorizontalPadding,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? palette.accent.withValues(alpha: 0.7)
                : enabled
                ? palette.hairlineFor(brightness)
                : palette.hairlineFor(brightness).withValues(alpha: 0.55),
            width: selected ? 1.3 : 1,
          ),
        ),
        child: icon == null
            ? Text(
                label ?? '',
                style: TextStyle(
                  color: foreground,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              )
            : Icon(icon, color: foreground, size: 20),
      ),
    );
  }
}

class _KeySurface extends StatefulWidget {
  const _KeySurface({
    required this.color,
    required this.child,
    this.onPressed,
    this.repeat = false,
  });

  final Color color;
  final Widget child;
  final VoidCallback? onPressed;
  final bool repeat;

  @override
  State<_KeySurface> createState() => _KeySurfaceState();
}

class _KeySurfaceState extends State<_KeySurface> {
  Timer? _delayTimer;
  Timer? _repeatTimer;
  bool _holding = false;
  bool _dragCanceled = false;
  bool _repeatStarted = false;
  Offset? _pointerStart;

  @override
  void dispose() {
    _stopRepeat();
    super.dispose();
  }

  void _pressOnce() {
    final onPressed = widget.onPressed;
    if (onPressed == null) {
      return;
    }
    onPressed();
  }

  void _startPress(Offset position) {
    final onPressed = widget.onPressed;
    if (onPressed == null) {
      return;
    }
    _pointerStart = position;
    _dragCanceled = false;
    _repeatStarted = false;
    if (!widget.repeat) {
      return;
    }
    _holding = true;
    _delayTimer?.cancel();
    _repeatTimer?.cancel();
    _delayTimer = Timer(_repeatInitialDelay, () {
      if (!_holding || _dragCanceled) {
        return;
      }
      _repeatStarted = true;
      onPressed();
      _repeatTimer = Timer.periodic(_repeatInterval, (_) {
        if (_holding && !_dragCanceled) {
          onPressed();
        }
      });
    });
  }

  void _trackMove(Offset position) {
    final pointerStart = _pointerStart;
    if (pointerStart == null || _dragCanceled) {
      return;
    }
    if ((position - pointerStart).distance <= kTouchSlop) {
      return;
    }
    _dragCanceled = true;
    _stopRepeat();
  }

  void _endPress() {
    final shouldPress =
        widget.onPressed != null && !_dragCanceled && !_repeatStarted;
    _stopRepeat();
    _pointerStart = null;
    if (shouldPress) {
      _pressOnce();
    }
  }

  void _cancelPress() {
    _dragCanceled = true;
    _pointerStart = null;
    _stopRepeat();
  }

  void _stopRepeat() {
    _holding = false;
    _delayTimer?.cancel();
    _delayTimer = null;
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: widget.color,
        borderRadius: BorderRadius.circular(8),
        child: Listener(
          onPointerDown: enabled
              ? (event) => _startPress(event.localPosition)
              : null,
          onPointerMove: enabled
              ? (event) => _trackMove(event.localPosition)
              : null,
          onPointerUp: enabled ? (_) => _endPress() : null,
          onPointerCancel: enabled ? (_) => _cancelPress() : null,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: enabled ? () {} : null,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _ToggleKey extends StatelessWidget {
  const _ToggleKey({
    required this.label,
    required this.palette,
    required this.brightness,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final AppPalette palette;
  final Brightness brightness;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final accent = palette.accent;
    final background = selected
        ? Color.alphaBlend(
            accent.withValues(alpha: 0.22),
            palette.panelFor(brightness),
          )
        : palette.panelFor(brightness);
    return _KeySurface(
      color: background,
      onPressed: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: _keyHeight,
        constraints: const BoxConstraints(minWidth: _textKeyMinWidth),
        padding: const EdgeInsets.symmetric(
          horizontal: _textKeyHorizontalPadding,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.7)
                : palette.hairlineFor(brightness),
            width: selected ? 1.3 : 1,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: TextStyle(
            color: selected ? accent : palette.foregroundFor(brightness),
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

class _MenuKey<T> extends StatelessWidget {
  const _MenuKey({
    required this.label,
    required this.tooltip,
    required this.items,
    required this.onSelected,
    required this.palette,
    required this.brightness,
  });

  final String label;
  final String tooltip;
  final List<PopupMenuEntry<T>> items;
  final ValueChanged<T> onSelected;
  final AppPalette palette;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: PopupMenuButton<T>(
        tooltip: tooltip,
        onSelected: onSelected,
        itemBuilder: (context) => items,
        child: Container(
          height: 36,
          constraints: const BoxConstraints(minWidth: 44),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.panelFor(brightness),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: palette.hairlineFor(brightness)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: palette.foregroundFor(brightness),
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

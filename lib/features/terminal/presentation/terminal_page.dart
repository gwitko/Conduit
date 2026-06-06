import 'package:conduit/core/presentation/conduit_brand.dart';
import 'package:conduit/core/presentation/system_navigation_insets.dart';
import 'package:conduit/core/theme/app_palette.dart';
import 'package:conduit/core/theme/terminal_appearance.dart';
import 'package:conduit/core/theme/theme_controller.dart';
import 'package:conduit/features/terminal/presentation/terminal_keyboard_bar.dart';
import 'package:conduit/features/terminal/presentation/terminal_session_controller.dart';
import 'package:conduit/features/terminal/presentation/terminal_workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xterm/xterm.dart';

class TerminalPage extends StatefulWidget {
  const TerminalPage({
    required this.workspace,
    required this.themeController,
    super.key,
  });

  final TerminalWorkspaceController workspace;
  final ThemeController themeController;

  @override
  State<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  final _focusNode = FocusNode();
  TerminalSessionController? _focusedSession;
  bool _fullscreen = false;

  @override
  void initState() {
    super.initState();
    widget.workspace.addListener(_handleWorkspaceChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusedSession = widget.workspace.activeSession;
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _setSystemUiFullscreen(false);
    widget.workspace.removeListener(_handleWorkspaceChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleWorkspaceChanged() {
    final active = widget.workspace.activeSession;
    if (active == null || active == _focusedSession) return;
    _focusedSession = active;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _toggleFullscreen() {
    setState(() => _fullscreen = !_fullscreen);
    _setSystemUiFullscreen(_fullscreen);
  }

  void _setSystemUiFullscreen(bool fullscreen) {
    SystemChrome.setEnabledSystemUIMode(
      fullscreen ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.themeController,
      builder: (context, _) {
        final palette = widget.themeController.palette;
        return Scaffold(
          body: ListenableBuilder(
            listenable: widget.workspace,
            builder: (context, _) {
              final activeSession = widget.workspace.activeSession;
              final brightness = Theme.of(context).brightness;
              if (activeSession == null) {
                return ConduitBackdrop(
                  palette: palette,
                  child: SafeArea(
                    bottom: shouldApplyBottomSafeArea(context),
                    child: _EmptyTerminalState(
                      onBack: () => Navigator.of(context).pop(),
                    ),
                  ),
                );
              }

              final landscape =
                  MediaQuery.orientationOf(context) == Orientation.landscape;
              final gestureNavigation = usesAndroidGestureNavigation(context);
              return SafeArea(
                top: !_fullscreen,
                bottom: shouldApplyBottomSafeArea(context),
                left: !_fullscreen && (!landscape || !gestureNavigation),
                right: !_fullscreen && (!landscape || !gestureNavigation),
                child: Column(
                  children: [
                    if (!_fullscreen) ...[
                      _TerminalHeader(
                        session: activeSession,
                        palette: palette,
                        brightness: brightness,
                        onBack: () => Navigator.of(context).pop(),
                        onReconnect: () async {
                          await activeSession.disconnect();
                          await activeSession.connect();
                          _focusNode.requestFocus();
                        },
                      ),
                      _SessionTabs(
                        workspace: widget.workspace,
                        activeSession: activeSession,
                        palette: palette,
                        brightness: brightness,
                        onChanged: () => _focusNode.requestFocus(),
                      ),
                    ],
                    Expanded(
                      child: Container(
                        color: palette.terminalBackgroundFor(brightness),
                        child: IndexedStack(
                          index: widget.workspace.sessions.indexOf(
                            activeSession,
                          ),
                          children: [
                            for (final session in widget.workspace.sessions)
                              _TerminalSurface(
                                key: ValueKey(session.host.id),
                                session: session,
                                palette: palette,
                                brightness: brightness,
                                fontFamily: widget
                                    .themeController
                                    .terminalFont
                                    .fontFamily,
                                fontSize:
                                    widget.themeController.terminalFontSize,
                                focusNode: session == activeSession
                                    ? _focusNode
                                    : null,
                              ),
                          ],
                        ),
                      ),
                    ),
                    TerminalKeyboardBar(
                      controller: activeSession,
                      focusNode: _focusNode,
                      palette: palette,
                      brightness: brightness,
                      actions: widget.themeController.terminalKeyboardActions,
                      fullscreen: _fullscreen,
                      onToggleFullscreen: _toggleFullscreen,
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _TerminalSurface extends StatefulWidget {
  const _TerminalSurface({
    required this.session,
    required this.palette,
    required this.brightness,
    required this.fontFamily,
    required this.fontSize,
    required this.focusNode,
    super.key,
  });

  final TerminalSessionController session;
  final AppPalette palette;
  final Brightness brightness;
  final String fontFamily;
  final double fontSize;
  final FocusNode? focusNode;

  @override
  State<_TerminalSurface> createState() => _TerminalSurfaceState();
}

class _TerminalSurfaceState extends State<_TerminalSurface> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _connectIfNeeded());
  }

  @override
  void didUpdateWidget(covariant _TerminalSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _connectIfNeeded());
    }
  }

  Future<void> _connectIfNeeded() async {
    if (!mounted || !widget.session.shouldConnect) return;
    await widget.session.connect();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: TerminalView(
        widget.session.terminal,
        focusNode: widget.focusNode,
        autofocus: widget.focusNode != null,
        deleteDetection: true,
        keyboardType: TextInputType.visiblePassword,
        keyboardAppearance: Brightness.dark,
        theme: widget.palette.terminalThemeFor(widget.brightness),
        textStyle: TerminalStyle(
          fontFamily: widget.fontFamily,
          fontSize: widget.fontSize,
        ),
        padding: const EdgeInsets.fromLTRB(0, 6, 0, 4),
        cursorType: TerminalCursorType.block,
        alwaysShowCursor: true,
        simulateScroll: true,
      ),
    );
  }
}

class _TerminalHeader extends StatelessWidget {
  const _TerminalHeader({
    required this.session,
    required this.palette,
    required this.brightness,
    required this.onBack,
    required this.onReconnect,
  });

  final TerminalSessionController session;
  final AppPalette palette;
  final Brightness brightness;
  final VoidCallback onBack;
  final VoidCallback onReconnect;

  @override
  Widget build(BuildContext context) {
    final foreground = palette.foregroundFor(brightness);
    final muted = palette.mutedForegroundFor(brightness);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: palette.canvasFor(brightness),
        border: Border(
          bottom: BorderSide(color: palette.hairlineFor(brightness)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Machines',
            color: foreground,
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: onBack,
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: -0.1,
                  ),
                ),
                Text(
                  '${session.host.username}@${session.host.host}:${session.host.port}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: muted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          _StatusBadge(status: session.status),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Reconnect',
            color: foreground,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: onReconnect,
          ),
        ],
      ),
    );
  }
}

class _SessionTabs extends StatelessWidget {
  const _SessionTabs({
    required this.workspace,
    required this.activeSession,
    required this.palette,
    required this.brightness,
    required this.onChanged,
  });

  final TerminalWorkspaceController workspace;
  final TerminalSessionController activeSession;
  final AppPalette palette;
  final Brightness brightness;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: palette.canvasFor(brightness),
        border: Border(
          bottom: BorderSide(color: palette.hairlineFor(brightness)),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        itemCount: workspace.sessions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 4),
        itemBuilder: (context, index) {
          final session = workspace.sessions[index];
          final selected = session == activeSession;
          return _SessionTab(
            session: session,
            selected: selected,
            palette: palette,
            brightness: brightness,
            onTap: () {
              workspace.activate(session);
              onChanged();
            },
            onClose: () async {
              await workspace.close(session);
              onChanged();
              if (!context.mounted) return;
              if (!workspace.hasSessions) {
                Navigator.of(context).pop();
              }
            },
          );
        },
      ),
    );
  }
}

class _SessionTab extends StatelessWidget {
  const _SessionTab({
    required this.session,
    required this.selected,
    required this.palette,
    required this.brightness,
    required this.onTap,
    required this.onClose,
  });

  final TerminalSessionController session;
  final bool selected;
  final AppPalette palette;
  final Brightness brightness;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final foreground = palette.foregroundFor(brightness);
    final muted = palette.mutedForegroundFor(brightness);
    final accent = palette.accent;
    final background = selected
        ? Color.alphaBlend(
            accent.withValues(alpha: 0.14),
            palette.panelFor(brightness),
          )
        : palette.panelFor(brightness);
    final border = selected
        ? accent.withValues(alpha: 0.55)
        : palette.hairlineFor(brightness);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          constraints: const BoxConstraints(minWidth: 130, maxWidth: 230),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          padding: const EdgeInsets.only(left: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StatusDot(status: session.status),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  session.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(
                width: 26,
                height: 26,
                child: IconButton(
                  tooltip: 'Close',
                  iconSize: 14,
                  padding: EdgeInsets.zero,
                  color: muted,
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final TerminalConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    final palette = _statusPalette(status, Theme.of(context));
    return ConduitStatusPill(label: palette.label, color: palette.color);
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final TerminalConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    final palette = _statusPalette(status, Theme.of(context));
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: palette.color, shape: BoxShape.circle),
    );
  }
}

({Color color, String label}) _statusPalette(
  TerminalConnectionStatus status,
  ThemeData theme,
) {
  return switch (status) {
    TerminalConnectionStatus.connected => (
      color: const Color(0xFF22C55E),
      label: 'Live',
    ),
    TerminalConnectionStatus.connecting => (
      color: const Color(0xFFEAB308),
      label: 'Linking',
    ),
    TerminalConnectionStatus.failed => (
      color: theme.colorScheme.error,
      label: 'Failed',
    ),
    TerminalConnectionStatus.idle || TerminalConnectionStatus.disconnected => (
      color: const Color(0xFF64748B),
      label: 'Idle',
    ),
  };
}

class _EmptyTerminalState extends StatelessWidget {
  const _EmptyTerminalState({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ConduitGlyph(size: 48),
            const SizedBox(height: 16),
            Text('No sessions open', style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Pick a machine to spin up a new tab.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back to machines'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:conduit/core/presentation/conduit_brand.dart';
import 'package:conduit/core/presentation/system_navigation_insets.dart';
import 'package:conduit/core/theme/app_palette.dart';
import 'package:conduit/core/theme/terminal_appearance.dart';
import 'package:conduit/core/theme/theme_controller.dart';
import 'package:conduit/features/terminal/domain/security_key_interaction.dart';
import 'package:conduit/features/terminal/presentation/security_key_pin_dialog.dart';
import 'package:conduit/features/terminal/presentation/terminal_keyboard_bar.dart';
import 'package:conduit/features/terminal/presentation/terminal_session_controller.dart';
import 'package:conduit/features/terminal/presentation/terminal_workspace_controller.dart';
import 'package:conduit/features/terminal/presentation/widgets/empty_terminal_state.dart';
import 'package:conduit/features/terminal/presentation/widgets/session_tabs.dart';
import 'package:conduit/features/terminal/presentation/widgets/terminal_header.dart';
import 'package:conduit/features/terminal/presentation/widgets/terminal_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  bool _tmuxScrollMode = false;

  @override
  void initState() {
    super.initState();
    SecurityKeyInteraction.instance.registerPinPrompt(_promptSecurityKeyPin);
    widget.workspace.addListener(_handleWorkspaceChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusedSession = widget.workspace.activeSession;
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _setSystemUiFullscreen(false);
    SecurityKeyInteraction.instance.unregisterPinPrompt(_promptSecurityKeyPin);
    widget.workspace.removeListener(_handleWorkspaceChanged);
    _focusNode.dispose();
    super.dispose();
  }

  Future<String?> _promptSecurityKeyPin(SecurityKeyPinRequest request) {
    if (!mounted) {
      return Future<String?>.value();
    }
    return showSecurityKeyPinDialog(context, request);
  }

  void _handleWorkspaceChanged() {
    final active = widget.workspace.activeSession;
    if (active == null || active == _focusedSession) return;
    _focusedSession = active;
    if (_tmuxScrollMode) {
      setState(() => _tmuxScrollMode = false);
    }
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
                    child: EmptyTerminalState(
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
                      TerminalHeader(
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
                      SessionTabs(
                        workspace: widget.workspace,
                        activeSession: activeSession,
                        palette: palette,
                        brightness: brightness,
                        onChanged: _focusNode.requestFocus,
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
                              TerminalSurface(
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
                                onFontSizeChanged: (fontSize) {
                                  unawaited(
                                    widget.themeController.setTerminalFontSize(
                                      fontSize,
                                    ),
                                  );
                                },
                                predictiveEchoEnabled:
                                    session.host.predictiveEchoEnabled,
                                focusNode: session == activeSession
                                    ? _focusNode
                                    : null,
                                tmuxScrollMode:
                                    session == activeSession && _tmuxScrollMode,
                                onExitTmuxScrollMode: () {
                                  setState(() => _tmuxScrollMode = false);
                                  _focusNode.requestFocus();
                                },
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
                      items: widget.themeController.terminalKeyboardItems,
                      fullscreen: _fullscreen,
                      onToggleFullscreen: _toggleFullscreen,
                      tmuxPrefixKey: activeSession.host.tmuxPrefixKey,
                      tmuxScrollMode: _tmuxScrollMode,
                      onEnterTmuxScrollMode: () {
                        setState(() => _tmuxScrollMode = true);
                        _focusNode.requestFocus();
                      },
                      onExitTmuxScrollMode: () {
                        setState(() => _tmuxScrollMode = false);
                        _focusNode.requestFocus();
                      },
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

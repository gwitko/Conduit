import 'package:conduit/core/theme/app_palette.dart';
import 'package:conduit/features/terminal/presentation/terminal_session_controller.dart';
import 'package:flutter/material.dart';

class TerminalHeader extends StatelessWidget {
  const TerminalHeader({
    required this.session,
    required this.palette,
    required this.brightness,
    required this.onBack,
    required this.onReconnect,
    this.attentionCount = 0,
    this.onOpenAgentAttention,
    super.key,
  });

  final TerminalSessionController session;
  final AppPalette palette;
  final Brightness brightness;
  final VoidCallback onBack;
  final VoidCallback onReconnect;

  /// Number of monitored agents currently needing attention (badge).
  final int attentionCount;

  /// Opens the Agent Attention dashboard; null hides the button.
  final VoidCallback? onOpenAgentAttention;

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
                  session.host.endpoint,
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
          if (onOpenAgentAttention != null)
            IconButton(
              tooltip: 'Agents',
              color: foreground,
              icon: Badge.count(
                count: attentionCount,
                isLabelVisible: attentionCount > 0,
                child: const Icon(Icons.monitor_heart_outlined),
              ),
              onPressed: onOpenAgentAttention,
            ),
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

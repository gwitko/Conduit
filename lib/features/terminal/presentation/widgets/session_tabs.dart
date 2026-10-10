import 'package:conduit/core/l10n/l10n.dart';
import 'package:conduit/core/theme/app_palette.dart';
import 'package:conduit/features/terminal/presentation/terminal_session_controller.dart';
import 'package:conduit/features/terminal/presentation/terminal_workspace_controller.dart';
import 'package:flutter/material.dart';

class SessionTabs extends StatelessWidget {
  const SessionTabs({
    required this.workspace,
    required this.activeSession,
    required this.palette,
    required this.brightness,
    required this.onChanged,
    super.key,
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
          width: 190,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          padding: const EdgeInsets.only(left: 10),
          child: Row(
            children: [
              _StatusDot(status: session.status),
              const SizedBox(width: 7),
              Expanded(
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
                  tooltip: context.l10n.actionClose,
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

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final TerminalConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      TerminalConnectionStatus.connected => const Color(0xFF22C55E),
      TerminalConnectionStatus.connecting => const Color(0xFFEAB308),
      TerminalConnectionStatus.failed => Theme.of(context).colorScheme.error,
      TerminalConnectionStatus.idle ||
      TerminalConnectionStatus.disconnected => const Color(0xFF64748B),
    };
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

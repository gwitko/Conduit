import 'package:conduit/features/local_shell/domain/local_shell_state.dart';
import 'package:conduit/features/local_shell/presentation/local_shell_controller.dart';
import 'package:flutter/material.dart';

class LocalShellCard extends StatelessWidget {
  const LocalShellCard({
    required this.controller,
    required this.active,
    required this.onOpenSession,
    required this.onManage,
    super.key,
  });

  final LocalShellController controller;
  final bool active;
  final Future<void> Function() onOpenSession;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final state = controller.state;
        if (state.isUnsupported) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionHeader(context),
              const SizedBox(height: 10),
              _card(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Device',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Run commands locally, no server required.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.25,
          ),
        ),
      ],
    );
  }

  Widget _card(BuildContext context, LocalShellState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ready = state.isReady;
    final highlight = ready && active;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _onTap(state),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: highlight
                  ? colorScheme.primary.withValues(alpha: 0.55)
                  : colorScheme.outlineVariant,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              _Avatar(ready: ready),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Local shell',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _statusLine(state),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: state.stage == LocalShellStage.failed
                            ? colorScheme.error
                            : colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _trailing(context, state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _trailing(BuildContext context, LocalShellState state) {
    final colorScheme = Theme.of(context).colorScheme;
    if (state.isChecking || state.isBusy) {
      return SizedBox(
        width: 36,
        height: 36,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: state.progress,
            ),
          ),
        ),
      );
    }
    if (state.isReady) {
      return IconButton(
        tooltip: 'Manage',
        iconSize: 18,
        onPressed: onManage,
        icon: Icon(Icons.tune_rounded, color: colorScheme.onSurfaceVariant),
      );
    }
    return Icon(
      Icons.chevron_right_rounded,
      color: colorScheme.onSurfaceVariant,
    );
  }

  void _onTap(LocalShellState state) {
    if (state.isReady) {
      onOpenSession();
    } else if (!state.isChecking && !state.isBusy) {
      onManage();
    }
  }

  String _statusLine(LocalShellState state) {
    return switch (state.stage) {
      LocalShellStage.ready =>
        'Arch Linux · ${_formatBytes(state.diskUsageBytes)}',
      LocalShellStage.checking => 'Arch Linux · checking…',
      LocalShellStage.notInstalled => 'Arch Linux · tap to install (~142 MB)',
      LocalShellStage.downloading =>
        'Downloading… ${((state.progress ?? 0) * 100).toStringAsFixed(0)}%',
      LocalShellStage.extracting => 'Unpacking…',
      LocalShellStage.configuring => 'Configuring…',
      LocalShellStage.failed =>
        state.error?.message ?? 'Setup failed - tap to retry',
      LocalShellStage.unsupported => 'Not available on this device',
    };
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.ready});

  final bool ready;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.primary;
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: ready
              ? [accent, colorScheme.secondary]
              : [
                  colorScheme.surfaceContainerHigh,
                  colorScheme.surfaceContainerHigh,
                ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ready
              ? accent.withValues(alpha: 0.4)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Icon(
        Icons.terminal_rounded,
        size: 18,
        color: ready ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
      ),
    );
  }
}

String _formatBytes(int? bytes) {
  if (bytes == null || bytes <= 0) return 'ready';
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final fixed = unit == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  return '$fixed ${units[unit]}';
}

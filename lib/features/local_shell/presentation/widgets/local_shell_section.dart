import 'package:conduit/core/l10n/l10n.dart';
import 'package:conduit/features/local_shell/domain/local_shell_instance.dart';
import 'package:conduit/features/local_shell/domain/local_shell_state.dart';
import 'package:conduit/features/local_shell/presentation/local_shell_controller.dart';
import 'package:conduit/features/local_shell/presentation/local_shell_setup_page.dart';
import 'package:flutter/material.dart';

class LocalShellSection extends StatelessWidget {
  const LocalShellSection({
    required this.controller,
    required this.activeInstanceIds,
    required this.onAdd,
    required this.onOpenInstance,
    required this.onManageInstance,
    super.key,
  });

  final LocalShellController controller;
  final Set<String> activeInstanceIds;
  final VoidCallback onAdd;
  final Future<void> Function(LocalShellInstance instance) onOpenInstance;
  final void Function(LocalShellInstance instance) onManageInstance;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.isUnsupported) return const SizedBox.shrink();
        final instances = controller.instances;
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionHeader(
                showAdd: !controller.isChecking && instances.isNotEmpty,
                onAdd: onAdd,
              ),
              const SizedBox(height: 10),
              if (controller.isChecking)
                const _CheckingCard()
              else if (instances.isEmpty)
                _SetupPromptCard(onTap: onAdd)
              else
                for (final instance in instances) ...[
                  _InstanceCard(
                    instance: instance,
                    distroName:
                        controller.distroById(instance.distroId)?.name ??
                        instance.distroId,
                    state: controller.stateFor(instance.id),
                    active: activeInstanceIds.contains(instance.id),
                    onOpen: () => onOpenInstance(instance),
                    onManage: () => onManageInstance(instance),
                  ),
                  if (instance != instances.last) const SizedBox(height: 8),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.showAdd, required this.onAdd});

  final bool showAdd;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.labelDevice,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                context.l10n.localShellHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
        if (showAdd)
          IconButton(
            tooltip: context.l10n.localShellNew,
            visualDensity: VisualDensity.compact,
            onPressed: onAdd,
            icon: Icon(
              Icons.add_circle_outline_rounded,
              color: colorScheme.primary,
            ),
          ),
      ],
    );
  }
}

class _CheckingCard extends StatelessWidget {
  const _CheckingCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _CardShell(
      highlighted: false,
      child: Row(
        children: [
          const _Avatar(ready: false),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.localShellChecking,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 9),
        ],
      ),
    );
  }
}

class _SetupPromptCard extends StatelessWidget {
  const _SetupPromptCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: _CardShell(
          highlighted: false,
          child: Row(
            children: [
              const _Avatar(ready: false),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.localShellSetUp,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.localShellSetupCaption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstanceCard extends StatelessWidget {
  const _InstanceCard({
    required this.instance,
    required this.distroName,
    required this.state,
    required this.active,
    required this.onOpen,
    required this.onManage,
  });

  final LocalShellInstance instance;
  final String distroName;
  final LocalShellState state;
  final bool active;
  final Future<void> Function() onOpen;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ready = state.isReady;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          if (ready) {
            onOpen();
          } else if (!state.isBusy) {
            onManage();
          }
        },
        child: _CardShell(
          highlighted: ready && active,
          child: Row(
            children: [
              _Avatar(ready: ready),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      instance.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _statusLine(context.l10n),
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
              _trailing(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _trailing(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (state.isBusy) {
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
    return IconButton(
      tooltip: context.l10n.actionManage,
      iconSize: 18,
      onPressed: onManage,
      icon: Icon(Icons.tune_rounded, color: colorScheme.onSurfaceVariant),
    );
  }

  String _statusLine(AppLocalizations l10n) {
    return switch (state.stage) {
      LocalShellStage.ready => l10n.localShellStatusReady(
        distroName,
        formatLocalShellBytes(state.diskUsageBytes),
      ),
      LocalShellStage.checking => l10n.localShellStatusChecking(distroName),
      LocalShellStage.notInstalled => l10n.localShellStatusIncomplete(
        distroName,
      ),
      LocalShellStage.downloading => l10n.localShellStatusDownloading(
        ((state.progress ?? 0) * 100).toStringAsFixed(0),
      ),
      LocalShellStage.extracting => l10n.localShellStatusUnpacking,
      LocalShellStage.configuring => l10n.localShellStatusConfiguring,
      LocalShellStage.failed =>
        state.error?.message ?? l10n.localShellStatusFailed,
      LocalShellStage.unsupported => l10n.localShellErrorUnavailable,
    };
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.highlighted, required this.child});

  final bool highlighted;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlighted
              ? colorScheme.primary.withValues(alpha: 0.55)
              : colorScheme.outlineVariant,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      child: child,
    );
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

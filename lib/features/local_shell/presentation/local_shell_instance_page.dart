import 'dart:async';

import 'package:conduit/core/l10n/l10n.dart';
import 'package:conduit/features/local_shell/domain/local_shell_instance.dart';
import 'package:conduit/features/local_shell/domain/local_shell_state.dart';
import 'package:conduit/features/local_shell/presentation/local_shell_controller.dart';
import 'package:conduit/features/local_shell/presentation/local_shell_setup_page.dart';
import 'package:flutter/material.dart';

class LocalShellInstancePage extends StatefulWidget {
  const LocalShellInstancePage({
    required this.controller,
    required this.instanceId,
    required this.onOpenSession,
    required this.onCloseSessions,
    super.key,
  });

  final LocalShellController controller;

  final String instanceId;

  final Future<void> Function(LocalShellInstance instance) onOpenSession;

  final Future<void> Function(String instanceId) onCloseSessions;

  @override
  State<LocalShellInstancePage> createState() => _LocalShellInstancePageState();
}

class _LocalShellInstancePageState extends State<LocalShellInstancePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(widget.controller.refresh());
    });
  }

  LocalShellInstance? get _instance =>
      widget.controller.instanceById(widget.instanceId);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final instance = _instance;
        if (instance == null) {
          return const Scaffold(body: SizedBox.shrink());
        }
        final state = widget.controller.stateFor(instance.id);
        return Scaffold(
          appBar: AppBar(
            title: Text(instance.name),
            actions: [
              IconButton(
                tooltip: context.l10n.actionRename,
                onPressed: state.isBusy ? null : () => _rename(instance),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildContent(context, instance, state),
                  const SizedBox(height: 32),
                  const _CreditFooter(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    LocalShellInstance instance,
    LocalShellState state,
  ) {
    final distroName =
        widget.controller.distroById(instance.distroId)?.name ??
        instance.distroId;
    switch (state.stage) {
      case LocalShellStage.checking:
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [SizedBox(height: 8), LinearProgressIndicator()],
        );
      case LocalShellStage.downloading:
      case LocalShellStage.extracting:
      case LocalShellStage.configuring:
        return _Installing(state: state, distroName: distroName);
      case LocalShellStage.failed:
        return _Failed(
          error: state.error,
          onRetry: () => unawaited(widget.controller.install(instance.id)),
          onRemove: () => _confirmRemove(instance),
        );
      case LocalShellStage.notInstalled:
        return _Incomplete(
          onResume: () => unawaited(widget.controller.install(instance.id)),
          onRemove: () => _confirmRemove(instance),
        );
      case LocalShellStage.ready:
        return _Ready(
          state: state,
          distroName: distroName,
          updateCommand: widget.controller
              .distroById(instance.distroId)
              ?.updateCommand,
          sharedStorageFeatureEnabled:
              widget.controller.sharedStorageFeatureEnabled,
          sharedStorageAccessGranted:
              widget.controller.sharedStorageAccessGranted,
          onOpen: () => unawaited(widget.onOpenSession(instance)),
          onReinstall: () => _confirmReinstall(instance),
          onRemove: () => _confirmRemove(instance),
        );
      case LocalShellStage.unsupported:
        return const SizedBox.shrink();
    }
  }

  Future<void> _rename(LocalShellInstance instance) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _RenameDialog(initialName: instance.name),
    );
    if (name != null && name.trim().isNotEmpty) {
      await widget.controller.rename(instance.id, name);
    }
  }

  Future<void> _confirmReinstall(LocalShellInstance instance) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.localShellReinstallTitle(instance.name)),
        content: Text(context.l10n.localShellReinstallBody(instance.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.actionReinstall),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.onCloseSessions(instance.id);
      await widget.controller.reinstall(instance.id);
    }
  }

  Future<void> _confirmRemove(LocalShellInstance instance) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.localShellRemoveTitle(instance.name)),
        content: Text(context.l10n.localShellRemoveBody(instance.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.actionRemove),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.onCloseSessions(instance.id);
      await widget.controller.remove(instance.id);
      if (mounted) Navigator.of(context).pop();
    }
  }
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initialName});

  final String initialName;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialName,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.localShellRenameTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(labelText: context.l10n.labelName),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(context.l10n.actionRename),
        ),
      ],
    );
  }
}

class _Ready extends StatelessWidget {
  const _Ready({
    required this.state,
    required this.distroName,
    required this.updateCommand,
    required this.sharedStorageFeatureEnabled,
    required this.sharedStorageAccessGranted,
    required this.onOpen,
    required this.onReinstall,
    required this.onRemove,
  });

  final LocalShellState state;
  final String distroName;
  final String? updateCommand;
  final bool sharedStorageFeatureEnabled;
  final bool sharedStorageAccessGranted;
  final VoidCallback onOpen;
  final VoidCallback onReinstall;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final storageStatus = !sharedStorageFeatureEnabled
        ? l10n.localShellFullBuildOnly
        : sharedStorageAccessGranted
        ? '/mnt/android'
        : l10n.localShellPermissionNeeded;
    final storageHint = sharedStorageFeatureEnabled
        ? l10n.localShellMountHint
        : l10n.localShellMountUnavailable;
    final updateHint = updateCommand == null
        ? ''
        : l10n.localShellUpdateHint(updateCommand!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Hero(
          icon: Icons.check_circle_outline_rounded,
          title: context.l10n.localShellReadyTitle(distroName),
          body: l10n.localShellReadyBody,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onOpen,
          icon: const Icon(Icons.terminal_rounded),
          label: Text(context.l10n.localShellNewSession),
        ),
        const SizedBox(height: 24),
        _InfoRow(label: context.l10n.labelDistribution, value: distroName),
        _InfoRow(
          label: context.l10n.labelVersion,
          value: state.installedVersion ?? context.l10n.commonUnknown,
        ),
        _InfoRow(
          label: context.l10n.labelDiskUsage,
          value: formatLocalShellBytes(state.diskUsageBytes),
        ),
        _InfoRow(label: context.l10n.labelAndroidFiles, value: storageStatus),
        const SizedBox(height: 16),
        Text(
          '$updateHint$storageHint',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onReinstall,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(context.l10n.actionReinstall),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onRemove,
          style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
          icon: const Icon(Icons.delete_outline_rounded),
          label: Text(context.l10n.actionRemove),
        ),
      ],
    );
  }
}

class _Installing extends StatelessWidget {
  const _Installing({required this.state, required this.distroName});

  final LocalShellState state;
  final String distroName;

  @override
  Widget build(BuildContext context) {
    final progress = state.progress;
    final l10n = context.l10n;
    final stageBody = switch (state.stage) {
      LocalShellStage.downloading => l10n.localShellStageDownloading(
        distroName,
      ),
      LocalShellStage.extracting => l10n.localShellStageUnpacking,
      LocalShellStage.configuring => l10n.localShellStageConfiguring,
      _ => l10n.commonWorking,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Hero(
          icon: Icons.settings_suggest_outlined,
          title: context.l10n.localShellSettingUp(distroName),
          body: stageBody,
        ),
        const SizedBox(height: 24),
        LinearProgressIndicator(value: progress),
        if (progress != null) ...[
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({
    required this.error,
    required this.onRetry,
    required this.onRemove,
  });

  final LocalShellError? error;
  final VoidCallback onRetry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Hero(
          icon: Icons.error_outline_rounded,
          title: _title(context.l10n, error?.kind),
          body: error?.message ?? context.l10n.localShellSetupFailedBody,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(context.l10n.actionTryAgain),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onRemove,
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          icon: const Icon(Icons.delete_outline_rounded),
          label: Text(context.l10n.actionRemove),
        ),
      ],
    );
  }

  String _title(AppLocalizations l10n, LocalShellErrorKind? kind) {
    return switch (kind) {
      LocalShellErrorKind.network => l10n.localShellErrorDownload,
      LocalShellErrorKind.lowDisk => l10n.localShellErrorStorage,
      LocalShellErrorKind.corruptDownload => l10n.localShellErrorCorrupt,
      LocalShellErrorKind.extractionFailed => l10n.localShellErrorUnpack,
      LocalShellErrorKind.configureFailed => l10n.localShellErrorConfigure,
      LocalShellErrorKind.unsupportedDevice => l10n.localShellErrorUnavailable,
      LocalShellErrorKind.unknown || null => l10n.localShellErrorGeneric,
    };
  }
}

class _Incomplete extends StatelessWidget {
  const _Incomplete({required this.onResume, required this.onRemove});

  final VoidCallback onResume;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Hero(
          icon: Icons.downloading_rounded,
          title: context.l10n.localShellIncompleteTitle,
          body: context.l10n.localShellIncompleteBody,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onResume,
          icon: const Icon(Icons.download_rounded),
          label: Text(context.l10n.localShellResumeInstall),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onRemove,
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          icon: const Icon(Icons.delete_outline_rounded),
          label: Text(context.l10n.actionRemove),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 40, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _CreditFooter extends StatelessWidget {
  const _CreditFooter();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: theme.colorScheme.outlineVariant),
        const SizedBox(height: 8),
        Text(
          context.l10n.localShellLicensesBody,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () =>
                showLicensePage(context: context, applicationName: 'Conduit'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            icon: const Icon(Icons.description_outlined, size: 16),
            label: Text(context.l10n.labelOpenSourceLicenses),
          ),
        ),
      ],
    );
  }
}

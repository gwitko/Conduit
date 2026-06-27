import 'dart:async';

import 'package:conduit/features/local_shell/domain/local_shell_state.dart';
import 'package:conduit/features/local_shell/presentation/local_shell_controller.dart';
import 'package:flutter/material.dart';

class LocalShellPage extends StatefulWidget {
  const LocalShellPage({
    required this.controller,
    required this.onOpenSession,
    required this.onCloseSession,
    super.key,
  });

  final LocalShellController controller;

  final Future<void> Function() onOpenSession;

  final Future<void> Function() onCloseSession;

  @override
  State<LocalShellPage> createState() => _LocalShellPageState();
}

class _LocalShellPageState extends State<LocalShellPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(widget.controller.refresh());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Local shell')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildContent(context, widget.controller.state),
                  const SizedBox(height: 32),
                  const _CreditFooter(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, LocalShellState state) {
    switch (state.stage) {
      case LocalShellStage.checking:
        return const _Checking();
      case LocalShellStage.unsupported:
        return _Unsupported(message: state.error?.message);
      case LocalShellStage.notInstalled:
        return _NotInstalled(onInstall: widget.controller.install);
      case LocalShellStage.downloading:
      case LocalShellStage.extracting:
      case LocalShellStage.configuring:
        return _Installing(state: state);
      case LocalShellStage.failed:
        return _Failed(error: state.error, onRetry: widget.controller.install);
      case LocalShellStage.ready:
        return _Ready(
          state: state,
          onOpen: () => unawaited(widget.onOpenSession()),
          onReinstall: () => _confirmReinstall(context),
          onReset: () => _confirmReset(context),
        );
    }
  }

  Future<void> _confirmReinstall(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reinstall Arch Linux?'),
        content: const Text(
          'This wipes the current environment - including anything you '
          'installed with pacman - and downloads a fresh image. Any open '
          'local shell tab will be closed first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reinstall'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.onCloseSession();
      await widget.controller.reinstall();
    }
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove local shell?'),
        content: const Text(
          'This deletes the installed Arch Linux environment and everything '
          'in it. Any open local shell tab will be closed first. You can '
          'reinstall it later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.onCloseSession();
      await widget.controller.reset();
    }
  }
}

class _Checking extends StatelessWidget {
  const _Checking();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Hero(
          icon: Icons.search_rounded,
          title: 'Checking local shell',
          body: 'Looking for an installed Arch Linux environment.',
        ),
        SizedBox(height: 24),
        LinearProgressIndicator(),
      ],
    );
  }
}

class _Unsupported extends StatelessWidget {
  const _Unsupported({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return _Hero(
      icon: Icons.phonelink_erase_outlined,
      title: 'Not available on this device',
      body:
          message ??
          'The local Arch Linux shell needs a 64-bit ARM Android device.',
    );
  }
}

class _NotInstalled extends StatelessWidget {
  const _NotInstalled({required this.onInstall});

  final Future<void> Function() onInstall;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Hero(
          icon: Icons.terminal_rounded,
          title: 'Run Arch Linux on your device',
          body:
              'Install a full Arch Linux ARM userland with pacman, running '
              'locally through proot. The image downloads on first use.',
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onInstall,
          icon: const Icon(Icons.download_rounded),
          label: const Text('Install Arch Linux'),
        ),
        const SizedBox(height: 12),
        Text(
          'Downloads several hundred MB and uses ~1.5 GB once updated. '
          'Wi-Fi recommended.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _Installing extends StatelessWidget {
  const _Installing({required this.state});

  final LocalShellState state;

  @override
  Widget build(BuildContext context) {
    final progress = state.progress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Hero(
          icon: Icons.settings_suggest_outlined,
          title: 'Setting up Arch Linux',
          body: state.message ?? 'Working…',
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
  const _Failed({required this.error, required this.onRetry});

  final LocalShellError? error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Hero(
          icon: Icons.error_outline_rounded,
          title: _title(error?.kind),
          body: error?.message ?? 'Something went wrong during setup.',
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
      ],
    );
  }

  String _title(LocalShellErrorKind? kind) {
    return switch (kind) {
      LocalShellErrorKind.network => 'Download failed',
      LocalShellErrorKind.lowDisk => 'Not enough storage',
      LocalShellErrorKind.corruptDownload => 'Download was corrupted',
      LocalShellErrorKind.extractionFailed => 'Could not unpack the image',
      LocalShellErrorKind.keyringFailed => 'Configuration failed',
      LocalShellErrorKind.unsupportedDevice => 'Not available on this device',
      LocalShellErrorKind.unknown || null => 'Setup failed',
    };
  }
}

class _Ready extends StatelessWidget {
  const _Ready({
    required this.state,
    required this.onOpen,
    required this.onReinstall,
    required this.onReset,
  });

  final LocalShellState state;
  final VoidCallback onOpen;
  final VoidCallback onReinstall;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Hero(
          icon: Icons.check_circle_outline_rounded,
          title: 'Arch Linux is ready',
          body: 'Open a local shell and use pacman like any other terminal.',
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onOpen,
          icon: const Icon(Icons.terminal_rounded),
          label: const Text('Open shell'),
        ),
        const SizedBox(height: 24),
        _InfoRow(label: 'Version', value: state.installedVersion ?? 'unknown'),
        _InfoRow(
          label: 'Disk usage',
          value: _formatBytes(state.diskUsageBytes),
        ),
        const SizedBox(height: 16),
        Text(
          'Update packages from inside the shell with  pacman -Syu .',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onReinstall,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Reinstall'),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onReset,
          style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('Remove local shell'),
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
          'The local shell uses proot and an Arch Linux ARM image packaged '
          'through Termux. Conduit redistributes the bundled tools under '
          'their own open-source licenses.',
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
            label: const Text('Open-source licenses'),
          ),
        ),
      ],
    );
  }
}

String _formatBytes(int? bytes) {
  if (bytes == null || bytes <= 0) return 'unknown';
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

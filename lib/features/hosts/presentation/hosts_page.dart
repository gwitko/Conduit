import 'dart:async';

import 'package:conduit/core/presentation/conduit_brand.dart';
import 'package:conduit/core/presentation/system_navigation_insets.dart';
import 'package:conduit/core/presentation/theme_sheet.dart';
import 'package:conduit/core/theme/theme_controller.dart';
import 'package:conduit/features/app_lock/presentation/app_lock_controller.dart';
import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:conduit/features/hosts/presentation/host_form_page.dart';
import 'package:conduit/features/hosts/presentation/hosts_controller.dart';
import 'package:conduit/features/sftp/domain/file_export.dart';
import 'package:conduit/features/sftp/domain/sftp_repository.dart';
import 'package:conduit/features/sftp/presentation/sftp_browser_page.dart';
import 'package:conduit/features/terminal/domain/host_key_prompt.dart';
import 'package:conduit/features/terminal/domain/host_key_verifier.dart';
import 'package:conduit/features/terminal/domain/ssh_terminal_repository.dart';
import 'package:conduit/features/terminal/presentation/host_key_prompt_coordinator.dart';
import 'package:conduit/features/terminal/presentation/host_key_prompt_dialog.dart';
import 'package:conduit/features/terminal/presentation/terminal_page.dart';
import 'package:conduit/features/terminal/presentation/terminal_workspace_controller.dart';
import 'package:conduit/features/terminal/presentation/trusted_keys_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

class HostsPage extends StatefulWidget {
  const HostsPage({
    required this.hostsController,
    required this.lockController,
    required this.terminalRepository,
    required this.workspaceController,
    required this.themeController,
    required this.hostKeyVerifier,
    required this.promptCoordinator,
    required this.sftpRepository,
    required this.fileExport,
    super.key,
  });

  final HostsController hostsController;
  final AppLockController lockController;
  final SshTerminalRepository terminalRepository;
  final TerminalWorkspaceController workspaceController;
  final ThemeController themeController;
  final HostKeyVerifier hostKeyVerifier;
  final HostKeyPromptCoordinator promptCoordinator;
  final SftpRepository sftpRepository;
  final FileExport fileExport;

  @override
  State<HostsPage> createState() => _HostsPageState();
}

class _HostsPageState extends State<HostsPage> {
  final _searchController = TextEditingController();
  bool _terminalPageOpen = false;
  bool _showingHostKeyPrompt = false;
  String _query = '';
  String? _selectedTag;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(widget.hostsController.load());
      _handlePromptChanged();
    });
    widget.promptCoordinator.addListener(_handlePromptChanged);
  }

  @override
  void dispose() {
    widget.promptCoordinator.removeListener(_handlePromptChanged);
    widget.promptCoordinator.rejectAll();
    _searchController.dispose();
    super.dispose();
  }

  void _handlePromptChanged() {
    if (_showingHostKeyPrompt || !mounted) return;
    if (widget.promptCoordinator.current == null) return;
    _showingHostKeyPrompt = true;
    Future<void>.microtask(() async {
      try {
        while (true) {
          final next = widget.promptCoordinator.current;
          if (next == null) break;
          final decision = await _requestHostKeyDecision(next);
          widget.promptCoordinator.resolve(next, decision);
        }
      } finally {
        _showingHostKeyPrompt = false;
      }
    });
  }

  Future<HostKeyDecision> _requestHostKeyDecision(
    HostKeyPromptRequest request,
  ) async {
    if (!mounted) return HostKeyDecision.reject;
    return await showHostKeyPromptDialog(context: context, request: request) ??
        HostKeyDecision.reject;
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.themeController.palette;
    return Scaffold(
      floatingActionButton: _ConnectionFab(onTap: () => _openForm()),
      body: ConduitBackdrop(
        palette: palette,
        child: SafeArea(
          bottom: shouldApplyBottomSafeArea(context),
          child: RefreshIndicator(
            color: Theme.of(context).colorScheme.primary,
            onRefresh: widget.hostsController.load,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: ListenableBuilder(
                    listenable: Listenable.merge([
                      widget.hostsController,
                      widget.workspaceController,
                    ]),
                    builder: (context, _) {
                      return _Hero(
                        hostCount: widget.hostsController.hosts.length,
                        activeSessionCount:
                            widget.workspaceController.sessions.length,
                        onAppearance: () => showThemeSheet(
                          context: context,
                          controller: widget.themeController,
                        ),
                        onTrustedKeys: _openTrustedKeys,
                        onLock: _lock,
                        onOpenSessions: widget.workspaceController.hasSessions
                            ? _openTerminalWorkspace
                            : null,
                      );
                    },
                  ),
                ),
                ListenableBuilder(
                  listenable: Listenable.merge([
                    widget.hostsController,
                    widget.workspaceController,
                  ]),
                  builder: (context, _) => _buildBody(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final controller = widget.hostsController;
    if (controller.isLoading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (controller.errorMessage != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _MessageState(
          icon: Icons.error_outline,
          title: 'Something went wrong',
          message: controller.errorMessage!,
          actionLabel: 'Retry',
          onAction: controller.load,
        ),
      );
    }

    if (controller.hosts.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _MessageState(
          icon: Icons.dns_outlined,
          title: 'No machines yet',
          message:
              'Add a server and Conduit will keep its credentials in your '
              'device’s secure storage.',
          actionLabel: 'Add machine',
          onAction: () => _openForm(),
        ),
      );
    }

    final filteredHosts = _filteredHosts(controller.recentHosts);
    final tags = _tagsFor(controller.hosts);

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
      sliver: SliverList(
        delegate: SliverChildListDelegate.fixed([
          _HostSearchField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            hasContent: _query.isNotEmpty || _selectedTag != null,
            onClear: _clearFilters,
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            _TagFilterBar(
              tags: tags,
              selectedTag: _selectedTag,
              onSelected: (tag) {
                setState(() {
                  _selectedTag = _selectedTag == tag ? null : tag;
                });
              },
            ),
          ],
          const SizedBox(height: 16),
          if (filteredHosts.isEmpty)
            _MessageState(
              icon: Icons.search_off,
              title: 'No matches',
              message: 'Try a different search or clear filters.',
              actionLabel: 'Clear',
              onAction: _clearFilters,
            )
          else
            for (final host in filteredHosts) ...[
              _HostCard(
                host: host,
                active: widget.workspaceController.sessions.any(
                  (session) => session.host.id == host.id,
                ),
                selectedTag: _selectedTag,
                onConnect: () => _connect(host),
                onAction: (action) => _handleHostAction(action, host),
                onTagTap: (tag) {
                  setState(() {
                    _selectedTag = _selectedTag == tag ? null : tag;
                  });
                },
              ),
              const SizedBox(height: 8),
            ],
        ]),
      ),
    );
  }

  List<SavedHost> _filteredHosts(List<SavedHost> hosts) {
    final normalizedQuery = _query.trim().toLowerCase();
    return hosts.where((host) {
      final matchesTag =
          _selectedTag == null || host.tags.contains(_selectedTag);
      final matchesQuery =
          normalizedQuery.isEmpty ||
          host.name.toLowerCase().contains(normalizedQuery) ||
          host.host.toLowerCase().contains(normalizedQuery) ||
          host.username.toLowerCase().contains(normalizedQuery) ||
          host.tags.any((tag) => tag.toLowerCase().contains(normalizedQuery));
      return matchesTag && matchesQuery;
    }).toList();
  }

  List<String> _tagsFor(List<SavedHost> hosts) {
    final tags = <String>{};
    for (final host in hosts) {
      for (final tag in host.tags) {
        final trimmed = tag.trim();
        if (trimmed.isNotEmpty) tags.add(trimmed);
      }
    }
    final list = tags.toList();
    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _selectedTag = null;
    });
  }

  Future<void> _openTerminalWorkspace() async {
    if (_terminalPageOpen) return;
    _terminalPageOpen = true;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TerminalPage(
          workspace: widget.workspaceController,
          themeController: widget.themeController,
        ),
      ),
    );
    _terminalPageOpen = false;
  }

  Future<void> _openTrustedKeys() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TrustedKeysPage(
          verifier: widget.hostKeyVerifier,
          themeController: widget.themeController,
        ),
      ),
    );
  }

  Future<void> _openFiles(SavedHost host) async {
    await widget.hostsController.markConnected(host);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SftpBrowserPage(
          host: host,
          repository: widget.sftpRepository,
          fileExport: widget.fileExport,
          themeController: widget.themeController,
        ),
      ),
    );
  }

  Future<void> _connect(SavedHost host) async {
    await widget.hostsController.markConnected(host);
    widget.workspaceController.open(host);
    await _openTerminalWorkspace();
  }

  Future<void> _lock() async {
    await widget.workspaceController.closeAll();
    widget.lockController.lock();
  }

  Future<void> _openForm([SavedHost? host]) async {
    final savedHost = await Navigator.of(context).push<SavedHost>(
      MaterialPageRoute(
        builder: (_) =>
            HostFormPage(host: host, themeController: widget.themeController),
      ),
    );
    if (savedHost != null) {
      await widget.hostsController.upsert(savedHost);
    }
  }

  Future<void> _handleHostAction(_HostAction action, SavedHost host) async {
    switch (action) {
      case _HostAction.files:
        await _openFiles(host);
      case _HostAction.edit:
        await _openForm(host);
      case _HostAction.duplicate:
        await _duplicate(host);
      case _HostAction.copyAddress:
        await Clipboard.setData(ClipboardData(text: host.endpoint));
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Copied ${host.endpoint}')));
      case _HostAction.delete:
        await _confirmDelete(host);
    }
  }

  Future<void> _duplicate(SavedHost host) async {
    final keepSecrets = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplicate machine'),
        content: const Text(
          'Copy the saved password and key material into the new machine?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Without secrets'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Copy secrets'),
          ),
        ],
      ),
    );
    if (keepSecrets == null) return;
    final base = keepSecrets
        ? host
        : host.copyWith(password: '', privateKey: '', passphrase: '');
    await widget.hostsController.upsert(
      base.copyWith(
        id: const Uuid().v4(),
        name: '${host.name} Copy',
        clearLastConnectedAt: true,
      ),
    );
  }

  Future<void> _confirmDelete(SavedHost host) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete machine?'),
        content: Text('Conduit will forget “${host.name}”.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete ?? false) {
      await widget.hostsController.remove(host);
    }
  }
}

enum _HostAction { files, edit, duplicate, copyAddress, delete }

class _Hero extends StatelessWidget {
  const _Hero({
    required this.hostCount,
    required this.activeSessionCount,
    required this.onAppearance,
    required this.onTrustedKeys,
    required this.onLock,
    required this.onOpenSessions,
  });

  final int hostCount;
  final int activeSessionCount;
  final VoidCallback onAppearance;
  final VoidCallback onTrustedKeys;
  final VoidCallback onLock;
  final VoidCallback? onOpenSessions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: ConduitWordmark(size: 32, showSubtitle: true),
              ),
              _GhostIconButton(
                tooltip: 'Trusted keys',
                icon: Icons.shield_outlined,
                onPressed: onTrustedKeys,
              ),
              const SizedBox(width: 8),
              _GhostIconButton(
                tooltip: 'Appearance',
                icon: Icons.palette_outlined,
                onPressed: onAppearance,
              ),
              const SizedBox(width: 8),
              _GhostIconButton(
                tooltip: 'Lock',
                icon: Icons.lock_outline,
                onPressed: onLock,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _StatsRow(
            hostCount: hostCount,
            activeSessionCount: activeSessionCount,
          ),
          if (activeSessionCount > 0) ...[
            const SizedBox(height: 12),
            _ResumeBanner(
              activeSessionCount: activeSessionCount,
              onOpenSessions: onOpenSessions,
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'Machines',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$hostCount',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.hostCount, required this.activeSessionCount});

  final int hostCount;
  final int activeSessionCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Saved',
            value: '$hostCount',
            icon: Icons.storage_rounded,
            accent: false,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'Live sessions',
            value: '$activeSessionCount',
            icon: Icons.bolt_rounded,
            accent: activeSessionCount > 0,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accentColor = colorScheme.primary;
    final background = accent
        ? Color.alphaBlend(
            accentColor.withValues(alpha: 0.12),
            colorScheme.surface,
          )
        : colorScheme.surface;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent
              ? accentColor.withValues(alpha: 0.4)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: accent ? accentColor : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: accent ? accentColor : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.displaySmall?.copyWith(
              color: accent ? accentColor : colorScheme.onSurface,
              fontSize: 28,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumeBanner extends StatelessWidget {
  const _ResumeBanner({
    required this.activeSessionCount,
    required this.onOpenSessions,
  });

  final int activeSessionCount;
  final VoidCallback? onOpenSessions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpenSessions,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              accent.withValues(alpha: 0.16),
              colorScheme.surface,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.tab_rounded, size: 18, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resume sessions',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '$activeSessionCount active',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _GhostIconButton extends StatelessWidget {
  const _GhostIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 18, color: colorScheme.onSurface),
          ),
        ),
      ),
    );
  }
}

class _HostSearchField extends StatelessWidget {
  const _HostSearchField({
    required this.controller,
    required this.onChanged,
    required this.hasContent,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool hasContent;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search machines, hosts, tags…',
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: hasContent
            ? IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () {
                  controller.clear();
                  onClear();
                },
              )
            : null,
      ),
    );
  }
}

class _TagFilterBar extends StatelessWidget {
  const _TagFilterBar({
    required this.tags,
    required this.selectedTag,
    required this.onSelected,
  });

  final List<String> tags;
  final String? selectedTag;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final tag in tags) ...[
            _TagPill(
              label: tag,
              selected: selectedTag == tag,
              onTap: () => onSelected(tag),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.primary;
    final background = selected
        ? Color.alphaBlend(accent.withValues(alpha: 0.18), colorScheme.surface)
        : colorScheme.surface;
    final foreground = selected ? accent : colorScheme.onSurfaceVariant;
    final border = selected
        ? accent.withValues(alpha: 0.55)
        : colorScheme.outlineVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border, width: selected ? 1.3 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tag_rounded, size: 13, color: foreground),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HostCard extends StatelessWidget {
  const _HostCard({
    required this.host,
    required this.active,
    required this.selectedTag,
    required this.onConnect,
    required this.onAction,
    required this.onTagTap,
  });

  final SavedHost host;
  final bool active;
  final String? selectedTag;
  final VoidCallback onConnect;
  final ValueChanged<_HostAction> onAction;
  final ValueChanged<String> onTagTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authIcon = switch (host.authMethod) {
      SshAuthMethod.password => Icons.password_rounded,
      SshAuthMethod.privateKey => Icons.vpn_key_outlined,
      SshAuthMethod.hardwareKey => Icons.usb_rounded,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onConnect,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: active
                      ? colorScheme.primary.withValues(alpha: 0.55)
                      : colorScheme.outlineVariant,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HostAvatar(active: active),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                host.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${host.username}@${host.host}:${host.port}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            height: 1.25,
                          ),
                        ),
                        if (host.tags.isNotEmpty ||
                            host.lastConnectedAt != null) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 5,
                            runSpacing: 5,
                            children: [
                              _MetaChip(
                                icon: authIcon,
                                label: _authLabel(host),
                              ),
                              for (final tag in host.tags)
                                _MetaChip(
                                  icon: Icons.tag_rounded,
                                  label: tag,
                                  selected: selectedTag == tag,
                                  onTap: () => onTagTap(tag),
                                ),
                              if (host.lastConnectedAt != null)
                                _MetaChip(
                                  icon: Icons.history_rounded,
                                  label: _lastConnectedLabel(
                                    host.lastConnectedAt!,
                                  ),
                                ),
                            ],
                          ),
                        ] else ...[
                          const SizedBox(height: 6),
                          _MetaChip(icon: authIcon, label: _authLabel(host)),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: PopupMenuButton<_HostAction>(
                      tooltip: 'Machine options',
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      onSelected: onAction,
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: _HostAction.files,
                          child: ListTile(
                            leading: Icon(Icons.folder_open_outlined),
                            title: Text('Files'),
                            contentPadding: EdgeInsets.zero,
                            minLeadingWidth: 24,
                          ),
                        ),
                        PopupMenuItem(
                          value: _HostAction.edit,
                          child: ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Edit'),
                            contentPadding: EdgeInsets.zero,
                            minLeadingWidth: 24,
                          ),
                        ),
                        PopupMenuItem(
                          value: _HostAction.duplicate,
                          child: ListTile(
                            leading: Icon(Icons.copy_rounded),
                            title: Text('Duplicate'),
                            contentPadding: EdgeInsets.zero,
                            minLeadingWidth: 24,
                          ),
                        ),
                        PopupMenuItem(
                          value: _HostAction.copyAddress,
                          child: ListTile(
                            leading: Icon(Icons.content_copy_rounded),
                            title: Text('Copy address'),
                            contentPadding: EdgeInsets.zero,
                            minLeadingWidth: 24,
                          ),
                        ),
                        PopupMenuItem(
                          value: _HostAction.delete,
                          child: ListTile(
                            leading: Icon(Icons.delete_outline_rounded),
                            title: Text('Delete'),
                            contentPadding: EdgeInsets.zero,
                            minLeadingWidth: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (active)
              Positioned(
                left: 0,
                top: 10,
                bottom: 10,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _authLabel(SavedHost host) => switch (host.authMethod) {
    SshAuthMethod.password => 'Password',
    SshAuthMethod.privateKey => 'Key',
    SshAuthMethod.hardwareKey => 'Hardware key',
  };

  String _lastConnectedLabel(DateTime last) {
    final diff = DateTime.now().difference(last);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }
}

class _HostAvatar extends StatelessWidget {
  const _HostAvatar({required this.active});

  final bool active;

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
          colors: active
              ? [accent, colorScheme.secondary]
              : [
                  colorScheme.surfaceContainerHigh,
                  colorScheme.surfaceContainerHigh,
                ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active
              ? accent.withValues(alpha: 0.4)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Icon(
        Icons.dns_rounded,
        size: 18,
        color: active ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.primary;
    final background = selected
        ? Color.alphaBlend(accent.withValues(alpha: 0.18), colorScheme.surface)
        : colorScheme.surfaceContainerHigh;
    final foreground = selected ? accent : colorScheme.onSurfaceVariant;
    final border = selected
        ? accent.withValues(alpha: 0.55)
        : colorScheme.outlineVariant;

    final chip = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: border, width: selected ? 1.2 : 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.5, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return chip;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: onTap,
        child: chip,
      ),
    );
  }
}

class _ConnectionFab extends StatelessWidget {
  const _ConnectionFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.secondary],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: colorScheme.onPrimary),
                const SizedBox(width: 6),
                Text(
                  'New machine',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.alphaBlend(
                  colorScheme.primary.withValues(alpha: 0.16),
                  colorScheme.surface,
                ),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Icon(icon, size: 28, color: colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

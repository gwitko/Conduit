import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:flutter/material.dart';

enum HostAction { files, edit, duplicate, copyAddress, delete }

class HostCard extends StatelessWidget {
  const HostCard({
    required this.host,
    required this.active,
    required this.selectedTag,
    required this.onConnect,
    required this.onAction,
    required this.onTagTap,
    this.dragHandle,
    super.key,
  });

  final SavedHost host;
  final bool active;
  final String? selectedTag;
  final VoidCallback onConnect;
  final ValueChanged<HostAction> onAction;
  final ValueChanged<String> onTagTap;
  final Widget? dragHandle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authIcon = switch (host.authMethod) {
      SshAuthMethod.password => Icons.password_rounded,
      SshAuthMethod.privateKey => Icons.vpn_key_outlined,
      SshAuthMethod.hardwareKey => Icons.usb_rounded,
      SshAuthMethod.external => Icons.link_rounded,
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
                          host.endpoint,
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
                  if (dragHandle != null)
                    SizedBox(
                      height: 36,
                      child: Center(
                        child: IconTheme.merge(
                          data: IconThemeData(
                            color: colorScheme.onSurfaceVariant,
                            size: 22,
                          ),
                          child: dragHandle!,
                        ),
                      ),
                    ),
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: PopupMenuButton<HostAction>(
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
                          value: HostAction.files,
                          child: ListTile(
                            leading: Icon(Icons.folder_open_outlined),
                            title: Text('Files'),
                            contentPadding: EdgeInsets.zero,
                            minLeadingWidth: 24,
                          ),
                        ),
                        PopupMenuItem(
                          value: HostAction.edit,
                          child: ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Edit'),
                            contentPadding: EdgeInsets.zero,
                            minLeadingWidth: 24,
                          ),
                        ),
                        PopupMenuItem(
                          value: HostAction.duplicate,
                          child: ListTile(
                            leading: Icon(Icons.copy_rounded),
                            title: Text('Duplicate'),
                            contentPadding: EdgeInsets.zero,
                            minLeadingWidth: 24,
                          ),
                        ),
                        PopupMenuItem(
                          value: HostAction.copyAddress,
                          child: ListTile(
                            leading: Icon(Icons.content_copy_rounded),
                            title: Text('Copy address'),
                            contentPadding: EdgeInsets.zero,
                            minLeadingWidth: 24,
                          ),
                        ),
                        PopupMenuItem(
                          value: HostAction.delete,
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
    SshAuthMethod.hardwareKey =>
      host.effectiveHardwareKeys.length > 1
          ? 'Hardware keys (${host.effectiveHardwareKeys.length})'
          : 'Hardware key',
    SshAuthMethod.external => 'External',
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

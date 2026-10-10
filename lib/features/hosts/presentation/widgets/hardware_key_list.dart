import 'package:conduit/core/l10n/l10n.dart';
import 'package:conduit/features/hosts/domain/saved_host.dart';
import 'package:conduit/features/hosts/domain/ssh_key.dart';
import 'package:flutter/material.dart';

class HardwareKeyList extends StatelessWidget {
  const HardwareKeyList({
    required this.entries,
    required this.inspections,
    required this.errorText,
    required this.onAdd,
    required this.onRename,
    required this.onRemove,
    required this.onViewPublicKey,
    super.key,
  });

  final List<HardwareKeyEntry> entries;
  final Map<String, SshKeyInspection> inspections;
  final String? errorText;
  final VoidCallback onAdd;
  final ValueChanged<HardwareKeyEntry> onRename;
  final ValueChanged<HardwareKeyEntry> onRemove;
  final ValueChanged<HardwareKeyEntry> onViewPublicKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                entries.isEmpty
                    ? context.l10n.hardwareKeysTitle
                    : context.l10n.hardwareKeysCount(entries.length),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (entries.isEmpty)
          _EmptyState()
        else
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _HardwareKeyCard(
              entry: entries[i],
              index: i,
              inspection: inspections[entries[i].id],
              onRename: () => onRename(entries[i]),
              onRemove: () => onRemove(entries[i]),
              onViewPublicKey: () => onViewPublicKey(entries[i]),
            ),
          ],
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(context.l10n.addHardwareKeyTitle),
          ),
        ),
      ],
    );
  }
}

String displayLabelForHardwareKey(
  AppLocalizations l10n,
  HardwareKeyEntry entry,
  int index,
  SshKeyInspection? inspection,
) {
  if (entry.label.trim().isNotEmpty) {
    return entry.label.trim();
  }
  final comment = inspection?.details?.comment.trim() ?? '';
  if (comment.isNotEmpty) {
    return comment;
  }
  return l10n.hardwareKeyItemTitle(index + 1);
}

class _HardwareKeyCard extends StatelessWidget {
  const _HardwareKeyCard({
    required this.entry,
    required this.index,
    required this.inspection,
    required this.onRename,
    required this.onRemove,
    required this.onViewPublicKey,
  });

  final HardwareKeyEntry entry;
  final int index;
  final SshKeyInspection? inspection;
  final VoidCallback onRename;
  final VoidCallback onRemove;
  final VoidCallback onViewPublicKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final details = inspection?.details;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 6, 8),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          colorScheme.primary.withValues(alpha: 0.07),
          colorScheme.surface,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.usb_rounded, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displayLabelForHardwareKey(
                    context.l10n,
                    entry,
                    index,
                    inspection,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (details != null) ...[
                const SizedBox(width: 8),
                Text(
                  details.algorithm.label,
                  maxLines: 1,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(width: 8),
              SizedBox(
                width: 32,
                height: 32,
                child: PopupMenuButton<_HardwareKeyAction>(
                  tooltip: context.l10n.hardwareKeysOptions,
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onSelected: (action) => switch (action) {
                    _HardwareKeyAction.rename => onRename(),
                    _HardwareKeyAction.remove => onRemove(),
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _HardwareKeyAction.rename,
                      child: Text(context.l10n.actionRename),
                    ),
                    PopupMenuItem(
                      value: _HardwareKeyAction.remove,
                      child: Text(context.l10n.actionRemove),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              details?.fingerprintSha256 ?? context.l10n.keyChecking,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: details == null ? null : onViewPublicKey,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.key_rounded, size: 16),
              label: Text(context.l10n.hostCardViewPublicKey),
            ),
          ),
        ],
      ),
    );
  }
}

enum _HardwareKeyAction { rename, remove }

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.usb_off_rounded,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.hardwareKeysEmpty,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

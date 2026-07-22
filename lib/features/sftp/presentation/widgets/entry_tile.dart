import 'package:conduit/features/sftp/domain/sftp_entry.dart';
import 'package:flutter/material.dart';

enum EntryAction { open, download, rename, delete, copyPath }

class EntryTile extends StatelessWidget {
  const EntryTile({
    required this.entry,
    required this.onTap,
    required this.onAction,
    super.key,
  });

  final SftpEntry entry;
  final VoidCallback onTap;
  final ValueChanged<EntryAction> onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 9, 4, 9),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              _EntryIcon(entry: entry),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(entry),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _EntryActionsButton(entry: entry, onAction: onAction),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle(SftpEntry entry) {
    final parts = <String>[];
    if (entry.isDirectory) {
      parts.add('folder');
    } else if (entry.isSymlink) {
      parts.add('link');
    } else if (entry.size != null) {
      parts.add(_formatSize(entry.size!));
    }
    final modified = entry.modifiedAt;
    if (modified != null) {
      parts.add(_formatDate(modified));
    }
    final perms = entry.permissionString;
    if (perms.isNotEmpty) {
      parts.add(perms);
    }
    return parts.join('  ·  ');
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    const units = ['KB', 'MB', 'GB', 'TB'];
    var size = bytes / 1024;
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    return '${size.toStringAsFixed(size >= 10 ? 0 : 1)} ${units[unit]}';
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}

class _EntryActionsButton extends StatelessWidget {
  const _EntryActionsButton({required this.entry, required this.onAction});

  final SftpEntry entry;
  final ValueChanged<EntryAction> onAction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 36,
      height: 36,
      child: PopupMenuButton<EntryAction>(
        tooltip: 'Item options',
        padding: EdgeInsets.zero,
        iconSize: 18,
        icon: Icon(
          Icons.more_vert_rounded,
          color: colorScheme.onSurfaceVariant,
        ),
        onSelected: onAction,
        itemBuilder: (context) => [
          if (!entry.isDirectory)
            const PopupMenuItem(
              value: EntryAction.open,
              child: ListTile(
                leading: Icon(Icons.open_in_new_rounded),
                title: Text('Open'),
                contentPadding: EdgeInsets.zero,
                minLeadingWidth: 24,
              ),
            ),
          PopupMenuItem(
            value: EntryAction.download,
            child: ListTile(
              leading: const Icon(Icons.download_rounded),
              title: Text(entry.isDirectory ? 'Download as tar' : 'Download'),
              contentPadding: EdgeInsets.zero,
              minLeadingWidth: 24,
            ),
          ),
          const PopupMenuItem(
            value: EntryAction.copyPath,
            child: ListTile(
              leading: Icon(Icons.copy_rounded),
              title: Text('Copy path'),
              contentPadding: EdgeInsets.zero,
              minLeadingWidth: 24,
            ),
          ),
          const PopupMenuItem(
            value: EntryAction.rename,
            child: ListTile(
              leading: Icon(Icons.drive_file_rename_outline_rounded),
              title: Text('Rename'),
              contentPadding: EdgeInsets.zero,
              minLeadingWidth: 24,
            ),
          ),
          PopupMenuItem(
            value: EntryAction.delete,
            child: ListTile(
              leading: Icon(
                Icons.delete_outline_rounded,
                color: colorScheme.error,
              ),
              title: const Text('Delete'),
              contentPadding: EdgeInsets.zero,
              minLeadingWidth: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryIcon extends StatelessWidget {
  const _EntryIcon({required this.entry});

  final SftpEntry entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (icon, accent) = switch (entry.kind) {
      SftpEntryKind.directory => (Icons.folder_rounded, true),
      SftpEntryKind.symlink => (Icons.link_rounded, false),
      _ => (Icons.insert_drive_file_outlined, false),
    };
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent
            ? Color.alphaBlend(
                colorScheme.primary.withValues(alpha: 0.16),
                colorScheme.surface,
              )
            : colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Icon(
        icon,
        size: 19,
        color: accent ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
    );
  }
}

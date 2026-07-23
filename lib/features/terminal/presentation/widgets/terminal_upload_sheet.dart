import 'package:conduit/features/terminal/presentation/terminal_upload_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Formats a byte count for display: `532 B`, `1.4 MB`, `2.1 GB`.
String formatUploadSize(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  const units = ['KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = -1;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit += 1;
  }
  return '${value.toStringAsFixed(value >= 100 ? 0 : 1)} ${units[unit]}';
}

/// Shows the confirm → progress → result flow for one upload batch.
///
/// The sheet drives [controller]; nothing uploads until the user confirms.
/// On success the user can insert the shell-quoted remote paths into the
/// terminal ([onInsert]) or copy them to the clipboard.
Future<void> showTerminalUploadSheet({
  required BuildContext context,
  required TerminalUploadController controller,
  required ValueChanged<String> onInsert,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: false,
    enableDrag: false,
    builder: (context) =>
        TerminalUploadSheet(controller: controller, onInsert: onInsert),
  );
}

class TerminalUploadSheet extends StatelessWidget {
  const TerminalUploadSheet({
    required this.controller,
    required this.onInsert,
    super.key,
  });

  final TerminalUploadController controller;
  final ValueChanged<String> onInsert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (controller.destination != null) ...[
                Text(
                  controller.destination!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final item in controller.items)
                      _UploadItemTile(item: item, phase: controller.phase),
                  ],
                ),
              ),
              if (controller.phase == TerminalUploadPhase.failed) ...[
                const SizedBox(height: 8),
                Text(
                  'Upload failed. Nothing was inserted; already-uploaded '
                  'files stay on the server.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _buildActions(context),
            ],
          ),
        );
      },
    );
  }

  String get _title {
    return switch (controller.phase) {
      TerminalUploadPhase.confirming => 'Upload to server',
      TerminalUploadPhase.connecting => 'Connecting…',
      TerminalUploadPhase.uploading => 'Uploading…',
      TerminalUploadPhase.success => 'Uploaded',
      TerminalUploadPhase.failed => 'Upload failed',
      TerminalUploadPhase.cancelled => 'Upload cancelled',
    };
  }

  Widget _buildActions(BuildContext context) {
    switch (controller.phase) {
      case TerminalUploadPhase.confirming:
        return Row(
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: controller.uploadAll,
              icon: const Icon(Icons.upload_rounded),
              label: const Text('Upload'),
            ),
          ],
        );
      case TerminalUploadPhase.connecting:
      case TerminalUploadPhase.uploading:
        return Row(
          children: [
            const Spacer(),
            TextButton(
              onPressed: controller.cancel,
              child: const Text('Cancel'),
            ),
          ],
        );
      case TerminalUploadPhase.success:
      case TerminalUploadPhase.cancelled:
      case TerminalUploadPhase.failed:
        final paths = controller.quotedPathsForInsertion;
        return Row(
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            const Spacer(),
            if (paths.isNotEmpty) ...[
              IconButton(
                tooltip: 'Copy paths',
                icon: const Icon(Icons.copy_rounded),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: paths));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Remote paths copied.')),
                  );
                },
              ),
              const SizedBox(width: 6),
              FilledButton.icon(
                onPressed: () {
                  onInsert(paths);
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.keyboard_return_rounded),
                label: const Text('Insert path'),
              ),
            ],
          ],
        );
    }
  }
}

class _UploadItemTile extends StatelessWidget {
  const _UploadItemTile({required this.item, required this.phase});

  final TerminalUploadItem item;
  final TerminalUploadPhase phase;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = item.done
        ? item.remotePath ?? formatUploadSize(item.file.size)
        : '${formatUploadSize(item.bytesSent)} of '
              '${formatUploadSize(item.file.size)}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                item.done
                    ? Icons.check_circle_rounded
                    : Icons.insert_drive_file_outlined,
                size: 18,
                color: item.done
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                formatUploadSize(item.file.size),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          if (phase == TerminalUploadPhase.uploading && !item.done) ...[
            const SizedBox(height: 4),
            LinearProgressIndicator(value: item.fraction),
          ],
          if (item.done || phase != TerminalUploadPhase.confirming)
            Padding(
              padding: const EdgeInsets.only(left: 26, top: 2),
              child: Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

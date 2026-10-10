import 'package:conduit/core/l10n/l10n.dart';
import 'package:conduit/features/sftp/presentation/sftp_browser_controller.dart';
import 'package:flutter/material.dart';

class TransferBar extends StatelessWidget {
  const TransferBar({required this.transfer, super.key});

  final SftpTransfer transfer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                transfer.isUpload
                    ? Icons.upload_rounded
                    : Icons.download_rounded,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.sftpTransferProgress(
                    transfer.isUpload
                        ? context.l10n.sftpUploading
                        : context.l10n.sftpDownloading,
                    transfer.name,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: transfer.fraction,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

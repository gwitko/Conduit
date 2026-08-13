import 'package:flutter/material.dart';

class KeySourceActions extends StatelessWidget {
  const KeySourceActions({
    required this.onImportFile,
    required this.onPaste,
    this.onGenerate,
    this.onDownloadFromKey,
    super.key,
  });

  final VoidCallback onImportFile;
  final VoidCallback onPaste;
  final VoidCallback? onGenerate;
  final VoidCallback? onDownloadFromKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SourceButton(
            icon: Icons.upload_file_rounded,
            label: 'Import',
            onPressed: onImportFile,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SourceButton(
            icon: Icons.content_paste_rounded,
            label: 'Paste',
            onPressed: onPaste,
          ),
        ),
        if (onGenerate != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _SourceButton(
              icon: Icons.auto_awesome_rounded,
              label: 'Generate',
              onPressed: onGenerate!,
            ),
          ),
        ],
        if (onDownloadFromKey != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _SourceButton(
              icon: Icons.sim_card_download_rounded,
              label: 'From key',
              onPressed: onDownloadFromKey!,
            ),
          ),
        ],
      ],
    );
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        visualDensity: VisualDensity.compact,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

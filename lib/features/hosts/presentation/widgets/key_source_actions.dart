import 'package:conduit/core/l10n/l10n.dart';
import 'package:flutter/material.dart';

class KeySourceActions extends StatelessWidget {
  const KeySourceActions({
    required this.onImportFile,
    required this.onPaste,
    this.onGenerate,
    super.key,
  });

  final VoidCallback onImportFile;
  final VoidCallback onPaste;
  final VoidCallback? onGenerate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SourceButton(
            icon: Icons.upload_file_rounded,
            label: context.l10n.actionImport,
            onPressed: onImportFile,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SourceButton(
            icon: Icons.content_paste_rounded,
            label: context.l10n.actionPaste,
            onPressed: onPaste,
          ),
        ),
        if (onGenerate != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _SourceButton(
              icon: Icons.auto_awesome_rounded,
              label: context.l10n.actionGenerate,
              onPressed: onGenerate!,
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

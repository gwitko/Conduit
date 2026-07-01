import 'package:conduit/features/hosts/domain/ssh_key.dart';
import 'package:conduit/features/hosts/presentation/widgets/key_source_actions.dart';
import 'package:conduit/features/hosts/presentation/widgets/ssh_key_summary.dart';
import 'package:flutter/material.dart';

class HardwareKeysEditor extends StatelessWidget {
  const HardwareKeysEditor({
    required this.inspections,
    required this.errorText,
    required this.onImport,
    required this.onPaste,
    required this.onRemove,
    required this.onView,
    super.key,
  });

  final List<SshKeyInspection> inspections;
  final String? errorText;
  final VoidCallback onImport;
  final VoidCallback onPaste;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onView;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KeySourceActions(onImportFile: onImport, onPaste: onPaste),
        const SizedBox(height: 14),
        if (inspections.isEmpty)
          _EmptyHint(errorText: errorText)
        else ...[
          for (var index = 0; index < inspections.length; index++) ...[
            _HardwareKeyRow(
              inspection: inspections[index],
              onView: () => onView(index),
              onRemove: () => onRemove(index),
            ),
            if (index != inspections.length - 1) const SizedBox(height: 10),
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
        ],
      ],
    );
  }
}

class _HardwareKeyRow extends StatelessWidget {
  const _HardwareKeyRow({
    required this.inspection,
    required this.onView,
    required this.onRemove,
  });

  final SshKeyInspection inspection;
  final VoidCallback onView;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SshKeySummary(
            inspection: inspection,
            onViewPublicKey: onView,
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: 'Remove hardware key',
          onPressed: onRemove,
          icon: Icon(
            Icons.close_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.errorText});

  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasError = errorText != null;
    final accent = hasError ? colorScheme.error : colorScheme.onSurfaceVariant;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError ? colorScheme.error.withValues(alpha: 0.5) : colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.usb_rounded, size: 18, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              errorText ??
                  'Import or paste one or more id_ed25519_sk / id_ecdsa_sk '
                      'stubs. Any enrolled key can then unlock this machine.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: accent,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

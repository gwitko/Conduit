import 'dart:convert';

import 'package:conduit/core/l10n/l10n.dart';
import 'package:conduit/core/presentation/conduit_brand.dart';
import 'package:conduit/core/presentation/system_navigation_insets.dart';
import 'package:conduit/core/theme/app_theme.dart';
import 'package:conduit/features/hosts/domain/ssh_key.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> showPublicKeySheet({
  required BuildContext context,
  required SshKeyDetails details,
  bool freshlyGenerated = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemUiOverlayStyle(Theme.of(context).brightness),
      child: _PublicKeySheet(
        details: details,
        freshlyGenerated: freshlyGenerated,
      ),
    ),
  );
}

class _PublicKeySheet extends StatelessWidget {
  const _PublicKeySheet({
    required this.details,
    required this.freshlyGenerated,
  });

  final SshKeyDetails details;
  final bool freshlyGenerated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.62,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return SafeArea(
          bottom: shouldApplyBottomSafeArea(context),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
            children: [
              Row(
                children: [
                  Text(
                    freshlyGenerated
                        ? context.l10n.publicKeyCreatedTitle
                        : context.l10n.publicKeyTitle,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  const ConduitGlyph(size: 24),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                freshlyGenerated
                    ? context.l10n.publicKeyCreatedBody(details.algorithm.label)
                    : context.l10n.publicKeyInstructions,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),
              _PublicKeyBox(publicKey: details.publicKeyOpenSsh),
              const SizedBox(height: 10),
              Text(
                details.fingerprintSha256,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: 'monospace',
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _copy(context),
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: Text(context.l10n.actionCopy),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _save(context),
                      icon: const Icon(Icons.save_alt_rounded, size: 18),
                      label: Text(context.l10n.publicKeySave),
                    ),
                  ),
                ],
              ),
              if (freshlyGenerated) ...[
                const SizedBox(height: 16),
                _PrivateKeyNote(),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: details.publicKeyOpenSsh));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.publicKeyCopied)));
  }

  Future<void> _save(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final bytes = Uint8List.fromList(
      utf8.encode('${details.publicKeyOpenSsh}\n'),
    );
    try {
      final path = await FilePicker.saveFile(
        fileName: _fileName(details.algorithm),
        bytes: bytes,
      );
      if (path == null) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.publicKeySaved)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.publicKeySaveFailed)));
    }
  }

  String _fileName(SshKeyAlgorithm algorithm) => switch (algorithm) {
    SshKeyAlgorithm.ed25519 => 'id_ed25519.pub',
    SshKeyAlgorithm.rsa => 'id_rsa.pub',
    SshKeyAlgorithm.ecdsa => 'id_ecdsa.pub',
    SshKeyAlgorithm.securityKeyEd25519 => 'id_ed25519_sk.pub',
    SshKeyAlgorithm.securityKeyEcdsa => 'id_ecdsa_sk.pub',
    SshKeyAlgorithm.unknown => 'id_key.pub',
  };
}

class _PublicKeyBox extends StatelessWidget {
  const _PublicKeyBox({required this.publicKey});

  final String publicKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: SelectableText(
        publicKey,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12.5,
          height: 1.35,
        ),
      ),
    );
  }
}

class _PrivateKeyNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          colorScheme.primary.withValues(alpha: 0.08),
          colorScheme.surface,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 18, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.publicKeyPrivateNote,
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

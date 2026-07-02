import 'package:conduit/features/hosts/domain/ssh_key.dart';
import 'package:flutter/material.dart';

class SshKeySummary extends StatelessWidget {
  const SshKeySummary({
    required this.inspection,
    required this.onViewPublicKey,
    super.key,
  });

  final SshKeyInspection inspection;
  final VoidCallback onViewPublicKey;

  @override
  Widget build(BuildContext context) {
    final details = inspection.details;
    return switch (inspection.status) {
      SshKeyStatus.valid when details != null => _KeyCard(
        details: details,
        onViewPublicKey: onViewPublicKey,
      ),
      SshKeyStatus.securityKeyStub when details != null => _KeyCard(
        details: details,
        onViewPublicKey: onViewPublicKey,
      ),
      SshKeyStatus.needsPassphrase => const _KeyNotice(
        icon: Icons.lock_outline_rounded,
        message:
            'This key is encrypted. Enter its passphrase below to unlock it.',
        tone: _NoticeTone.info,
      ),
      SshKeyStatus.verifying => const _KeyChecking(),
      SshKeyStatus.wrongPassphrase => const _KeyNotice(
        icon: Icons.lock_reset_rounded,
        message: 'That passphrase did not match this key.',
        tone: _NoticeTone.error,
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _KeyCard extends StatelessWidget {
  const _KeyCard({required this.details, required this.onViewPublicKey});

  final SshKeyDetails details;
  final VoidCallback onViewPublicKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
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
              Icon(
                details.isSecurityKey
                    ? Icons.usb_rounded
                    : Icons.verified_user_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                details.algorithm.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (details.comment.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    details.comment,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            details.fingerprintSha256,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onViewPublicKey,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.key_rounded, size: 16),
              label: const Text('View public key'),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyChecking extends StatelessWidget {
  const _KeyChecking();

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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Checking passphrase…',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _NoticeTone { info, error }

class _KeyNotice extends StatelessWidget {
  const _KeyNotice({
    required this.icon,
    required this.message,
    required this.tone,
  });

  final IconData icon;
  final String message;
  final _NoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = tone == _NoticeTone.error
        ? colorScheme.error
        : colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          accent.withValues(alpha: 0.08),
          colorScheme.surface,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

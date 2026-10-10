import 'package:conduit/core/l10n/l10n.dart';
import 'package:conduit/features/terminal/domain/host_key_prompt.dart';
import 'package:flutter/material.dart';

Future<HostKeyDecision?> showHostKeyPromptDialog({
  required BuildContext context,
  required HostKeyPromptRequest request,
}) {
  final isMismatch = request.kind == HostKeyPromptKind.mismatch;
  return showDialog<HostKeyDecision>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final colorScheme = Theme.of(context).colorScheme;
      return AlertDialog(
        icon: Icon(
          isMismatch ? Icons.warning_amber_rounded : Icons.shield_outlined,
          color: isMismatch ? colorScheme.error : colorScheme.primary,
        ),
        title: Text(
          isMismatch
              ? context.l10n.hostKeyChangedTitle
              : context.l10n.hostKeyTrustTitle,
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isMismatch)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    context.l10n.hostKeyMismatchBody(
                      request.host,
                      request.port,
                    ),
                    style: TextStyle(color: colorScheme.error),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    context.l10n.hostKeyUnknownBody(request.host, request.port),
                  ),
                ),
              _PromptField(
                label: context.l10n.labelHost,
                value: '${request.host}:${request.port}',
              ),
              _PromptField(
                label: context.l10n.labelAlgorithm,
                value: request.type,
              ),
              _PromptField(
                label: context.l10n.labelFingerprint,
                value: request.fingerprint,
              ),
              if (isMismatch && request.existing != null) ...[
                const Divider(height: 24),
                Text(
                  context.l10n.hostKeyPreviouslyTrusted,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                _PromptField(
                  label: context.l10n.labelAlgorithm,
                  value: request.existing!.type,
                ),
                _PromptField(
                  label: context.l10n.labelFingerprint,
                  value: request.existing!.fingerprint,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(HostKeyDecision.reject),
            child: Text(context.l10n.actionReject),
          ),
          FilledButton(
            style: isMismatch
                ? FilledButton.styleFrom(backgroundColor: colorScheme.error)
                : null,
            onPressed: () => Navigator.of(context).pop(HostKeyDecision.trust),
            child: Text(
              isMismatch
                  ? context.l10n.hostKeyTrustNew
                  : context.l10n.actionTrust,
            ),
          ),
        ],
      );
    },
  );
}

class _PromptField extends StatelessWidget {
  const _PromptField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.3,
            ),
          ),
          SelectableText(
            value,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

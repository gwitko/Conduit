import 'package:conduit/core/l10n/l10n.dart';
import 'package:conduit/core/presentation/conduit_brand.dart';
import 'package:flutter/material.dart';

class EmptyTerminalState extends StatelessWidget {
  const EmptyTerminalState({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ConduitGlyph(size: 48),
            const SizedBox(height: 16),
            Text(
              context.l10n.terminalNoSessions,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.hostsPickMachine,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text(context.l10n.terminalBackToMachines),
            ),
          ],
        ),
      ),
    );
  }
}

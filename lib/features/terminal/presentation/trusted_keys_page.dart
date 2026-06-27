import 'package:conduit/core/presentation/conduit_brand.dart';
import 'package:conduit/core/presentation/system_navigation_insets.dart';
import 'package:conduit/core/theme/theme_controller.dart';
import 'package:conduit/features/terminal/domain/host_key_verifier.dart';
import 'package:flutter/material.dart';

class TrustedKeysPage extends StatefulWidget {
  const TrustedKeysPage({
    required this.verifier,
    this.themeController,
    super.key,
  });

  final HostKeyVerifier verifier;
  final ThemeController? themeController;

  @override
  State<TrustedKeysPage> createState() => _TrustedKeysPageState();
}

class _TrustedKeysPageState extends State<TrustedKeysPage> {
  Future<List<HostKeyRecord>>? _future;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _future = widget.verifier.loadTrustedKeys();
    });
  }

  Future<void> _confirmRemove(HostKeyRecord record) async {
    final removed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forget trusted key?'),
        content: Text(
          'Conduit will prompt again the next time you connect to '
          '${record.host}:${record.port}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Forget'),
          ),
        ],
      ),
    );
    if (removed ?? false) {
      await widget.verifier.removeTrustedKey(record.host, record.port);
      if (mounted) _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.themeController?.palette;
    final body = SafeArea(
      bottom: shouldApplyBottomSafeArea(context),
      child: Column(
        children: [
          _Header(onBack: () => Navigator.of(context).pop()),
          Expanded(
            child: FutureBuilder<List<HostKeyRecord>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final records = snapshot.data ?? const [];
                if (records.isEmpty) return const _EmptyState();
                records.sort((a, b) => a.host.compareTo(b.host));
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                  itemCount: records.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final record = records[index];
                    return _TrustedKeyTile(
                      record: record,
                      onRemove: () => _confirmRemove(record),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      body: palette == null
          ? body
          : ConduitBackdrop(palette: palette, child: body),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trusted host keys', style: theme.textTheme.headlineSmall),
                Text(
                  'Servers Conduit has connected to before.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const ConduitGlyph(size: 26),
        ],
      ),
    );
  }
}

class _TrustedKeyTile extends StatelessWidget {
  const _TrustedKeyTile({required this.record, required this.onRemove});

  final HostKeyRecord record;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                colorScheme.primary.withValues(alpha: 0.16),
                colorScheme.surface,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.verified_user_outlined,
              color: colorScheme.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.host}:${record.port}',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  record.type,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: SelectableText(
                    record.fingerprint,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Forget',
            icon: const Icon(Icons.delete_outline_rounded),
            color: colorScheme.error,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.alphaBlend(
                  colorScheme.primary.withValues(alpha: 0.18),
                  colorScheme.surface,
                ),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Icon(
                Icons.shield_outlined,
                color: colorScheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text('No trusted keys yet', style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Connect to a host and you’ll be asked to trust its key - the '
              'fingerprint lands here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

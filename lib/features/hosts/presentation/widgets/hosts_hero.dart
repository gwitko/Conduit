import 'package:conduit/core/presentation/conduit_brand.dart';
import 'package:flutter/material.dart';

class HostsHero extends StatelessWidget {
  const HostsHero({
    required this.hostCount,
    required this.activeSessionCount,
    required this.onAppearance,
    required this.onTrustedKeys,
    required this.onLock,
    required this.onOpenSessions,
    super.key,
  });

  final int hostCount;
  final int activeSessionCount;
  final VoidCallback onAppearance;
  final VoidCallback onTrustedKeys;
  final VoidCallback onLock;
  final VoidCallback? onOpenSessions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const ConduitGlyph(size: 30),
              const Spacer(),
              _GhostIconButton(
                tooltip: 'Trusted keys',
                icon: Icons.shield_outlined,
                onPressed: onTrustedKeys,
              ),
              const SizedBox(width: 8),
              _GhostIconButton(
                tooltip: 'Appearance',
                icon: Icons.palette_outlined,
                onPressed: onAppearance,
              ),
              const SizedBox(width: 8),
              _GhostIconButton(
                tooltip: 'Lock',
                icon: Icons.lock_outline,
                onPressed: onLock,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _StatsRow(
            hostCount: hostCount,
            activeSessionCount: activeSessionCount,
          ),
          if (activeSessionCount > 0) ...[
            const SizedBox(height: 12),
            _ResumeBanner(
              activeSessionCount: activeSessionCount,
              onOpenSessions: onOpenSessions,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.hostCount, required this.activeSessionCount});

  final int hostCount;
  final int activeSessionCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Saved',
            value: '$hostCount',
            icon: Icons.storage_rounded,
            accent: false,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'Live sessions',
            value: '$activeSessionCount',
            icon: Icons.bolt_rounded,
            accent: activeSessionCount > 0,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accentColor = colorScheme.primary;
    final background = accent
        ? Color.alphaBlend(
            accentColor.withValues(alpha: 0.12),
            colorScheme.surface,
          )
        : colorScheme.surface;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent
              ? accentColor.withValues(alpha: 0.4)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: accent ? accentColor : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: accent ? accentColor : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.displaySmall?.copyWith(
              color: accent ? accentColor : colorScheme.onSurface,
              fontSize: 28,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumeBanner extends StatelessWidget {
  const _ResumeBanner({
    required this.activeSessionCount,
    required this.onOpenSessions,
  });

  final int activeSessionCount;
  final VoidCallback? onOpenSessions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpenSessions,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              accent.withValues(alpha: 0.16),
              colorScheme.surface,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.tab_rounded, size: 18, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resume sessions',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '$activeSessionCount active',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _GhostIconButton extends StatelessWidget {
  const _GhostIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 18, color: colorScheme.onSurface),
          ),
        ),
      ),
    );
  }
}

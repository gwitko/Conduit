import 'package:conduit/core/l10n/l10n.dart';
import 'package:conduit/core/theme/app_palette.dart';
import 'package:flutter/material.dart';

class ConduitWordmark extends StatelessWidget {
  const ConduitWordmark({
    super.key,
    this.size = 28,
    this.showSubtitle = false,
    this.subtitle,
  });

  final double size;
  final bool showSubtitle;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConduitGlyph(size: size * 0.95),
        SizedBox(width: size * 0.4),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conduit',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: size * 0.78,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
            if (showSubtitle) ...[
              SizedBox(height: size * 0.18),
              Text(
                subtitle ?? context.l10n.brandTagline,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: size * 0.4,
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class ConduitGlyph extends StatelessWidget {
  const ConduitGlyph({super.key, this.size = 28, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GlyphPainter(tint)),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = w * 0.1;

    final front = Path()
      ..moveTo(w * 0.264, h * 0.721)
      ..lineTo(w * 0.498, h * 0.5)
      ..lineTo(w * 0.264, h * 0.279);
    final back = Path()
      ..moveTo(w * 0.512, h * 0.721)
      ..lineTo(w * 0.746, h * 0.5)
      ..lineTo(w * 0.512, h * 0.279);

    final glow = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, stroke * 0.55);
    canvas.drawPath(front, glow);
    canvas.drawPath(back, glow);

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(back, base..color = color.withValues(alpha: 0.62));
    canvas.drawPath(front, base..color = color);
  }

  @override
  bool shouldRepaint(_GlyphPainter oldDelegate) => oldDelegate.color != color;
}

class ConduitBackdrop extends StatelessWidget {
  const ConduitBackdrop({
    required this.palette,
    required this.child,
    super.key,
  });

  final AppPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final canvas = palette.canvasFor(brightness);
    final glow = palette.accent.withValues(
      alpha: brightness == Brightness.dark ? 0.10 : 0.06,
    );
    final secondaryGlow = palette.accentSecondary.withValues(
      alpha: brightness == Brightness.dark ? 0.06 : 0.04,
    );
    return DecoratedBox(
      decoration: BoxDecoration(color: canvas),
      child: Stack(
        children: [
          Positioned(
            top: -160,
            left: -120,
            child: _Blob(color: glow, size: 360),
          ),
          Positioned(
            top: 80,
            right: -160,
            child: _Blob(color: secondaryGlow, size: 320),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class ConduitStatusPill extends StatelessWidget {
  const ConduitStatusPill({
    required this.label,
    required this.color,
    super.key,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: icon == null ? 9 : 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
          ] else ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class ConduitSectionLabel extends StatelessWidget {
  const ConduitSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }
}

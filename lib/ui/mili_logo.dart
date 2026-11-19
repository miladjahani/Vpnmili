import 'package:flutter/material.dart';

/// Refined, minimalist geometric MiliConfig emblem (rounded squircle + smooth ribbon M).
class MiliShieldLogo extends StatelessWidget {
  final double size;
  final Color? primaryColor;
  final Color? accentColor;

  const MiliShieldLogo({
    super.key,
    this.size = 28,
    this.primaryColor,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = primaryColor ?? scheme.primary;
    final accent = accentColor ?? scheme.secondary;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RefinedMiliMarkPainter(primary: primary, accent: accent),
      ),
    );
  }
}

class _RefinedMiliMarkPainter extends CustomPainter {
  final Color primary;
  final Color accent;

  const _RefinedMiliMarkPainter({required this.primary, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 128.0;
    final rect = Rect.fromLTWH(4 * s, 4 * s, 120 * s, 120 * s);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(32 * s));

    // Soft dark obsidian squircle fill
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1F2633),
            const Color(0xFF12161E),
          ],
        ).createShader(rect),
    );

    // Subtle hairline gradient rim
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withValues(alpha: 0.75),
            accent.withValues(alpha: 0.25),
          ],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2 * s,
    );

    // Sleek geometric ribbon "M"
    final mPath = Path()
      ..moveTo(34 * s, 88 * s)
      ..lineTo(34 * s, 44 * s)
      ..quadraticBezierTo(34 * s, 38 * s, 40 * s, 42 * s)
      ..lineTo(64 * s, 63 * s)
      ..lineTo(88 * s, 42 * s)
      ..quadraticBezierTo(94 * s, 38 * s, 94 * s, 44 * s)
      ..lineTo(94 * s, 88 * s);

    canvas.drawPath(
      mPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, primary],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11.5 * s
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_RefinedMiliMarkPainter oldDelegate) =>
      oldDelegate.primary != primary || oldDelegate.accent != accent;
}

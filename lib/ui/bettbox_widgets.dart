import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bettbox-style opaque, calm, high-contrast dashboard card with `InfoHeader`,
/// subtle tilted background watermark icon, and tactile press feedback.
class BettboxTileCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget> actions;
  final IconData? watermarkIcon;
  final String? watermarkEmoji;
  final double watermarkAngle;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Widget child;
  final EdgeInsetsGeometry contentPadding;

  const BettboxTileCard({
    super.key,
    required this.title,
    this.icon,
    this.actions = const [],
    this.watermarkIcon,
    this.watermarkEmoji,
    this.watermarkAngle = -0.2,
    this.onTap,
    this.borderColor,
    this.contentPadding = const EdgeInsets.fromLTRB(16, 4, 16, 16),
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final radius = BorderRadius.circular(18);

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        color: isLight ? Colors.white : scheme.surfaceContainer,
        border: Border.all(
          color: borderColor ?? scheme.outlineVariant,
          width: borderColor != null ? 1.2 : 0.85,
        ),
        boxShadow: isLight
            ? const [
                BoxShadow(
                  color: Color(0x0A000000),
                  offset: Offset(0, 2),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Stack(
              children: [
                if (watermarkIcon != null || watermarkEmoji != null)
                  PositionedDirectional(
                    end: -10,
                    bottom: -14,
                    child: IgnorePointer(
                      child: Transform.rotate(
                        angle: watermarkAngle,
                        child: watermarkEmoji != null
                            ? Opacity(
                                opacity: 0.11,
                                child: Text(
                                  watermarkEmoji!,
                                  style: const TextStyle(fontSize: 62),
                                ),
                              )
                            : Icon(
                                watermarkIcon,
                                size: 74,
                                color: scheme.onSurface.withValues(alpha: 0.045),
                              ),
                      ),
                    ),
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 13, 12, 6),
                      child: Row(
                        children: [
                          if (icon != null) ...[
                            Icon(
                              icon,
                              size: 16,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 7),
                          ],
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                          ...actions,
                        ],
                      ),
                    ),
                    Padding(padding: contentPadding, child: child),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bettbox-style opaque interactive pill chip.
class BettboxChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const BettboxChip({
    super.key,
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = active ? scheme.primaryContainer : scheme.surfaceContainerHigh;
    final fg = active ? scheme.primary : scheme.onSurface;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Smooth cubic-Bezier LineChart with vertical gradient fill & revision-driven repaint
/// (never freezes even when underlying speed lists update every second).
class BettboxLineChart extends StatelessWidget {
  final List<double> values;
  final int revision;
  final Color color;
  final double height;

  const BettboxLineChart({
    super.key,
    required this.values,
    required this.revision,
    required this.color,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _BettboxLineChartPainter(
            values: values,
            revision: revision,
            color: color,
            baselineColor: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
    );
  }
}

class _BettboxLineChartPainter extends CustomPainter {
  final List<double> values;
  final int revision;
  final Color color;
  final Color baselineColor;

  const _BettboxLineChartPainter({
    required this.values,
    required this.revision,
    required this.color,
    required this.baselineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Subtle baseline
    canvas.drawLine(
      Offset(0, size.height - 1.5),
      Offset(size.width, size.height - 1.5),
      Paint()
        ..color = baselineColor.withValues(alpha: 0.5)
        ..strokeWidth = 1,
    );

    final pts = values.length < 2 ? const [0.0, 0.0] : values;
    final maxVal = math.max(1024.0, pts.reduce(math.max));
    final stepX = size.width / (pts.length - 1);
    const topPad = 5.0;
    final usableH = size.height - topPad - 2.5;

    final coords = <Offset>[
      for (int i = 0; i < pts.length; i++)
        Offset(
          i * stepX,
          size.height - 2.5 - ((pts[i] / maxVal).clamp(0.0, 1.0)) * usableH,
        ),
    ];

    final path = Path()..moveTo(coords.first.dx, coords.first.dy);
    for (int i = 0; i < coords.length - 1; i++) {
      final p0 = coords[i];
      final p1 = coords[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(coords.last.dx, size.height - 1.5)
      ..lineTo(coords.first.dx, size.height - 1.5)
      ..close();

    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(0, size.height),
        [color.withValues(alpha: 0.24), color.withValues(alpha: 0.0)],
      );
    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(_BettboxLineChartPainter oldDelegate) =>
      oldDelegate.revision != revision || oldDelegate.color != color;
}

/// Bettbox-style opaque floating pill bottom navigation bar with spring pill animation.
class BettboxFloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final List<({IconData icon, String label})> items;

  const BettboxFloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final barBg = isLight ? Colors.white : scheme.surfaceContainerHigh;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: barBg,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: scheme.outlineVariant, width: 0.9),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isLight ? 0.08 : 0.34),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (int i = 0; i < items.length; i++)
                _NavPillItem(
                  icon: items[i].icon,
                  label: items[i].label,
                  selected: i == selectedIndex,
                  onTap: () {
                    if (i != selectedIndex) {
                      HapticFeedback.selectionClick();
                      onChanged(i);
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavPillItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavPillItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 15 : 12,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: selected ? scheme.primaryContainer : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 21,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: selected
                  ? Padding(
                      padding: const EdgeInsetsDirectional.only(start: 7),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

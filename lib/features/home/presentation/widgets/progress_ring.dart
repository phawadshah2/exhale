import 'dart:math' as math;

import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/tracking/domain/entities/daily_progress.dart';
import 'package:exhale/features/tracking/domain/entities/limit_status.dart';
import 'package:flutter/material.dart';

/// Today's ring: fills toward the limit, then shows the overflow in red.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    required this.progress,
    required this.child,
    this.size = 220,
    this.strokeWidth = 14,
    super.key,
  });

  final DailyProgress progress;
  final Widget child;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final status = context.exhale;
    final overflow = progress.limit == 0
        ? (progress.count > 0 ? 1.0 : 0.0)
        : math.min(1, progress.overBy / progress.limit).toDouble();

    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: progress.usedFraction),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, fill, _) => TweenAnimationBuilder<double>(
          tween: Tween(end: overflow),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, over, _) => CustomPaint(
            painter: _RingPainter(
              fill: fill,
              overflow: over,
              strokeWidth: strokeWidth,
              track: colors.surfaceContainerHigh,
              gradient: switch (progress.status) {
                LimitStatus.under => [
                  colors.secondaryContainer,
                  colors.primaryContainer,
                ],
                LimitStatus.at => [status.warning.solid, status.warning.solid],
                LimitStatus.over => [
                  colors.primaryContainer.withValues(alpha: 0.35),
                  colors.primaryContainer.withValues(alpha: 0.35),
                ],
              },
              overflowColor: status.danger.solid,
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.fill,
    required this.overflow,
    required this.strokeWidth,
    required this.track,
    required this.gradient,
    required this.overflowColor,
  });

  final double fill;
  final double overflow;
  final double strokeWidth;
  final Color track;
  final List<Color> gradient;
  final Color overflowColor;

  static const double _start = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    Paint stroke() => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, stroke()..color = track);

    if (fill > 0) {
      final sweep = 2 * math.pi * fill.clamp(0.0, 1.0);
      final shader = SweepGradient(
        colors: gradient,
        endAngle: math.max(sweep, 0.01),
        transform: const GradientRotation(_start),
      ).createShader(rect);
      canvas
        ..drawArc(
          rect,
          _start,
          sweep,
          false,
          stroke()
            ..shader = shader
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
            ..color = Colors.white.withValues(alpha: 0.35),
        )
        ..drawArc(rect, _start, sweep, false, stroke()..shader = shader);
    }

    if (overflow > 0) {
      canvas.drawArc(
        rect,
        _start,
        2 * math.pi * overflow.clamp(0.0, 1.0),
        false,
        stroke()..color = overflowColor,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fill != fill ||
      old.overflow != overflow ||
      old.strokeWidth != strokeWidth ||
      old.track != track ||
      old.overflowColor != overflowColor ||
      !_sameColors(old.gradient, gradient);

  static bool _sameColors(List<Color> a, List<Color> b) =>
      a.length == b.length &&
      [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((same) => same);
}

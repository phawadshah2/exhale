import 'dart:math' as math;

import 'package:exhale/core/theme/app_motion.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/tracking/domain/entities/daily_progress.dart';
import 'package:exhale/features/tracking/domain/entities/limit_status.dart';
import 'package:flutter/material.dart';

/// A day's ring: fills toward the limit. While it fills it is the safe
/// green; once it has filled, the whole ring takes the colour of the day's
/// status (amber at the limit, red over it). With no [progress] (a day before
/// the plan) only the track is drawn.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    required this.progress,
    required this.child,
    this.size = 220,
    this.strokeWidth = 14,
    super.key,
  });

  final DailyProgress? progress;
  final Widget child;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final status = context.exhale;
    final progress = this.progress;
    final target = progress?.usedFraction ?? 0;
    final finalColor = switch (progress?.status) {
      LimitStatus.at => status.warning.solid,
      LimitStatus.over => status.danger.solid,
      _ => null,
    };

    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: target),
        duration: AppMotion.fill,
        curve: AppMotion.fillCurve,
        builder: (context, fill, _) => CustomPaint(
          painter: _RingPainter(
            fill: fill,
            // How close the arc is to its end: the status colour fades in
            // over the last quarter.
            settle: target == 0 ? 1 : (fill / target).clamp(0.0, 1.0),
            strokeWidth: strokeWidth,
            track: colors.surfaceContainerHigh,
            gradient: [colors.secondaryContainer, colors.primaryContainer],
            finalColor: finalColor,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.fill,
    required this.settle,
    required this.strokeWidth,
    required this.track,
    required this.gradient,
    required this.finalColor,
  });

  final double fill;
  final double settle;
  final double strokeWidth;
  final Color track;
  final List<Color> gradient;

  /// The colour the whole ring ends in; null keeps the gradient.
  final Color? finalColor;

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

    if (fill <= 0) return;
    final sweep = 2 * math.pi * fill.clamp(0.0, 1.0);
    // The round caps reach past both ends of the arc. The gradient starts a
    // cap's width early (the sweep shader has no negative angles) so the
    // start cap is the first colour, not the last.
    final cap = (strokeWidth / 2) / radius;
    final shader = SweepGradient(
      endAngle: sweep + 2 * cap,
      colors: gradient,
      transform: GradientRotation(_start - cap),
    ).createShader(rect);
    // Faint halo: the arc blurred and drawn at low opacity.
    canvas
      ..saveLayer(
        rect.inflate(strokeWidth * 2),
        Paint()..color = const Color(0x2E000000),
      )
      ..drawArc(
        rect,
        _start,
        sweep,
        false,
        stroke()
          ..shader = shader
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      )
      ..restore()
      ..drawArc(rect, _start, sweep, false, stroke()..shader = shader);

    final end = finalColor;
    final blend = Curves.easeInOut.transform(
      ((settle - 0.75) / 0.25).clamp(0.0, 1.0),
    );
    if (end != null && blend > 0) {
      canvas.drawArc(
        rect,
        _start,
        sweep,
        false,
        stroke()..color = end.withValues(alpha: blend),
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fill != fill ||
      old.settle != settle ||
      old.strokeWidth != strokeWidth ||
      old.track != track ||
      old.finalColor != finalColor ||
      !_sameColors(old.gradient, gradient);

  static bool _sameColors(List<Color> a, List<Color> b) =>
      a.length == b.length &&
      [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((same) => same);
}

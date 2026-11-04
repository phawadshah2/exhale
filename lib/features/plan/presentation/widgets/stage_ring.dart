import 'dart:math' as math;

import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/fill_in.dart';
import 'package:exhale/features/plan/domain/services/plan_report.dart';
import 'package:exhale/features/tracking/domain/entities/limit_status.dart';
import 'package:flutter/material.dart';

/// A stage's ring with its limit inside, filled by what was used. A stage
/// [ahead] has a dashed track and no fill.
class StageRing extends StatelessWidget {
  const StageRing({
    required this.report,
    this.ahead = false,
    this.size = 44,
    super.key,
  });

  final StageReport report;
  final bool ahead;
  final double size;

  static const double _strokePerPoint = 4 / 44;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final fill = ahead || report.allowed == 0
        ? 0.0
        : (report.used / report.allowed).clamp(0.0, 1.0);
    final ring = SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: StageRingPainter(
          fill: fill,
          strokeWidth: size * _strokePerPoint,
          color: switch (report.status) {
            LimitStatus.over => context.exhale.danger.solid,
            LimitStatus.at => context.exhale.warning.solid,
            LimitStatus.under => colors.primaryContainer,
          },
          track: ahead ? colors.outlineVariant : colors.surfaceContainerHigh,
          dashed: ahead,
        ),
        // Fixed, as the ring is; the row beside it says the stage in full.
        child: Center(
          child: MediaQuery.withNoTextScaling(
            child: Text(
              '${report.stage.limit}',
              style: (size > 44 ? text.titleMedium : text.titleSmall)?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
    return MediaQuery.disableAnimationsOf(context) ? ring : FillIn(child: ring);
  }
}

class StageRingPainter extends CustomPainter {
  const StageRingPainter({
    required this.fill,
    required this.strokeWidth,
    required this.color,
    required this.track,
    required this.dashed,
  });

  final double fill;
  final double strokeWidth;
  final Color color;
  final Color track;
  final bool dashed;

  static const double _start = -math.pi / 2;
  static const double _dash = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = track;

    if (dashed) {
      final dashes = (2 * math.pi * radius / (2 * _dash)).round();
      final sweep = 2 * math.pi / dashes;
      for (var i = 0; i < dashes; i++) {
        canvas.drawArc(rect, _start + i * sweep, sweep / 2, false, trackPaint);
      }
    } else {
      canvas.drawCircle(center, radius, trackPaint);
    }

    if (fill <= 0) return;
    canvas.drawArc(
      rect,
      _start,
      2 * math.pi * fill,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(StageRingPainter old) =>
      old.fill != fill ||
      old.strokeWidth != strokeWidth ||
      old.color != color ||
      old.track != track ||
      old.dashed != dashed;
}

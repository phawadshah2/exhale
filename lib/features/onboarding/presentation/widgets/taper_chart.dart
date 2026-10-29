import 'dart:math' as math;

import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/home/presentation/widgets/history/chart_paint.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:flutter/material.dart';

/// The daily limit from today down to 0 on the quit day.
class TaperChart extends StatelessWidget {
  const TaperChart({required this.plan, super.key});

  final ReductionPlan plan;

  static const double height = 150;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final start = AppFormat.shortWeekdayDate(plan.startDay);
    final quit = AppFormat.shortWeekdayDate(plan.quitDay);
    return Semantics(
      label: '${plan.startLimit} today, 0 on $quit',
      excludeSemantics: true,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _TaperPainter(
            plan: plan,
            startLabel: start,
            quitLabel: quit,
            line: colors.primary,
            track: colors.outlineVariant,
            surface: context.theme.cardTheme.color ?? colors.surface,
            valueStyle: text.labelLarge!.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
            dateStyle: text.labelSmall!.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _TaperPainter extends CustomPainter {
  _TaperPainter({
    required this.plan,
    required this.startLabel,
    required this.quitLabel,
    required this.line,
    required this.track,
    required this.surface,
    required this.valueStyle,
    required this.dateStyle,
  });

  final ReductionPlan plan;
  final String startLabel;
  final String quitLabel;
  final Color line;
  final Color track;
  final Color surface;
  final TextStyle valueStyle;
  final TextStyle dateStyle;

  /// Most points drawn; long plans are sampled.
  static const int _maxPoints = 120;
  static const int _dots = 11;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 6.0;
    const top = 22.0;
    final right = size.width - 8;
    final baseline = size.height - 24;
    final days = plan.totalDays;

    Offset at(int dayIndex) => Offset(
      left + (right - left) * dayIndex / days,
      baseline -
          (baseline - top) *
              plan.limitOn(plan.startDay.addDays(dayIndex)) /
              plan.startLimit,
    );

    canvas.drawLine(
      Offset(0, baseline),
      Offset(size.width, baseline),
      Paint()
        ..color = track
        ..strokeWidth = 1,
    );

    final count = math.min(days, _maxPoints);
    final points = [
      for (var i = 0; i <= count; i++) at((days * i / count).round()),
    ];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final dot = Paint()..color = line.withValues(alpha: 0.55);
    for (var i = 1; i < _dots - 1; i++) {
      canvas.drawCircle(at((days * i / (_dots - 1)).round()), 2.5, dot);
    }
    canvas
      ..drawCircle(points.first, 5, Paint()..color = line)
      ..drawCircle(points.last, 6, Paint()..color = surface)
      ..drawCircle(
        points.last,
        6,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

    paintLabel(
      canvas,
      '${plan.startLimit} today',
      Offset(points.first.dx + 12, top - 8),
      valueStyle,
      align: TextAlign.left,
    );
    paintLabel(
      canvas,
      '0',
      Offset(right, baseline - 18),
      valueStyle,
      align: TextAlign.right,
    );
    paintLabel(
      canvas,
      startLabel,
      Offset(0, size.height - 8),
      dateStyle,
      align: TextAlign.left,
    );
    paintLabel(
      canvas,
      quitLabel,
      Offset(size.width, size.height - 8),
      dateStyle,
      align: TextAlign.right,
    );
  }

  @override
  bool shouldRepaint(_TaperPainter old) =>
      old.plan.startLimit != plan.startLimit ||
      old.plan.quitDay != plan.quitDay ||
      old.plan.startDay != plan.startDay ||
      old.line != line ||
      old.track != track ||
      old.surface != surface ||
      old.valueStyle != valueStyle ||
      old.dateStyle != dateStyle;
}

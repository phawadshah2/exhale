import 'dart:math' as math;

import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_motion.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/home/presentation/widgets/history/chart_paint.dart';
import 'package:exhale/features/tracking/domain/entities/all_time_series.dart';
import 'package:flutter/material.dart';

/// Every day since the plan began against the plan's stepped limit, to the
/// quit date. From 14 days a bold 7-day average sits over a faint daily
/// line.
class AllTimeChart extends StatelessWidget {
  const AllTimeChart({required this.series, required this.quitDay, super.key});

  final AllTimeSeries series;
  final LogicalDay quitDay;

  static const double height = 200;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: height,
      width: double.infinity,
      // The line draws from the first day onward when the chart appears.
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: AppMotion.fill,
        curve: AppMotion.fillCurve,
        builder: (context, reveal, _) => CustomPaint(
          painter: _AllTimePainter(
            reveal: reveal,
            series: series,
            quitDay: quitDay,
            accent: colors.primaryContainer,
            marker: colors.primary,
            flag: context.exhale.warning.solid,
            plan: colors.onSurface.withValues(alpha: 0.7),
            grid: colors.outlineVariant.withValues(alpha: 0.35),
            surface: colors.surfaceContainerHigh,
            labelStyle: context.textTheme.labelMedium!.copyWith(
              color: colors.onSurfaceVariant,
            ),
            markerStyle: context.textTheme.labelSmall!.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w700,
            ),
            flagStyle: context.textTheme.labelSmall!.copyWith(
              color: context.exhale.warning.solid,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// The legend under the chart.
class AllTimeLegend extends StatelessWidget {
  const AllTimeLegend({required this.series, super.key});

  final AllTimeSeries series;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = context.textTheme.labelMedium?.copyWith(
      color: colors.onSurfaceVariant,
    );
    final smoothed = series.average7 != null;
    Widget item(String name, Widget swatch) => Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        swatch,
        Text(name, style: style),
      ],
    );
    Widget line(Color color, {double thickness = 3}) => Container(
      width: 14,
      height: thickness,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        if (smoothed) ...[
          item('7-day average', line(colors.primaryContainer)),
          item(
            'Each day',
            line(colors.primaryContainer.withValues(alpha: 0.4), thickness: 2),
          ),
        ] else
          item('Your days', line(colors.primaryContainer)),
        item(
          'Your plan',
          Container(
            width: 14,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: colors.onSurface, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AllTimePainter extends CustomPainter {
  const _AllTimePainter({
    required this.reveal,
    required this.series,
    required this.quitDay,
    required this.accent,
    required this.marker,
    required this.flag,
    required this.plan,
    required this.grid,
    required this.surface,
    required this.labelStyle,
    required this.markerStyle,
    required this.flagStyle,
  });

  final double reveal;
  final AllTimeSeries series;
  final LogicalDay quitDay;
  final Color accent;
  final Color marker;
  final Color flag;
  final Color plan;
  final Color grid;
  final Color surface;
  final TextStyle labelStyle;
  final TextStyle markerStyle;
  final TextStyle flagStyle;

  static const double _inset = 10;
  static const double _top = 26;
  static const double _bottomInset = 30;

  @override
  void paint(Canvas canvas, Size size) {
    final limits = series.limits;
    final counts = series.counts;
    final average = series.average7;
    final points = limits.length;
    const left = _inset;
    final right = size.width - _inset;
    final bottom = size.height - _bottomInset;

    double xAt(int i) =>
        points <= 1 ? left : left + i / (points - 1) * (right - left);
    final peak = [...limits, ...counts, ...?average].fold<num>(1, math.max);
    final maxY = peak * 1.15;
    double yFor(num value) => bottom - value / maxY * (bottom - _top);

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final f in const [0.0, 0.5, 1.0]) {
      final y = _top + (bottom - _top) * f;
      canvas.drawLine(Offset(left, y), Offset(right, y), gridPaint);
    }

    final staircase = Path()..moveTo(xAt(0), yFor(limits.first));
    for (var i = 1; i < points; i++) {
      staircase
        ..lineTo(xAt(i), yFor(limits[i - 1]))
        ..lineTo(xAt(i), yFor(limits[i]));
    }
    canvas.drawPath(
      dashedPath(staircase, dash: 2),
      Paint()
        ..color = plan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );

    // The line runs from the first day to today, not to the quit day, so it
    // arrives as the ring on the day card finishes.
    final tipX = xAt(math.max(counts.length - 1, 0));
    final clipX = reveal >= 1 ? size.width : left + (tipX - left) * reveal + 2;
    canvas
      ..save()
      ..clipRect(Rect.fromLTRB(0, 0, clipX, size.height));
    final daily = [
      for (var i = 0; i < counts.length; i++) Offset(xAt(i), yFor(counts[i])),
    ];
    final main = average == null
        ? daily
        : [
            for (var i = 0; i < average.length; i++)
              Offset(xAt(i), yFor(average[i])),
          ];
    if (main.length > 1) {
      final line = Path()..moveTo(main.first.dx, main.first.dy);
      for (final p in main.skip(1)) {
        line.lineTo(p.dx, p.dy);
      }
      final area = Path.from(line)
        ..lineTo(main.last.dx, bottom)
        ..lineTo(main.first.dx, bottom)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              accent.withValues(alpha: 0.35),
              accent.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromLTRB(left, _top, right, bottom)),
      );
      if (average != null && daily.length > 1) {
        final faint = Path()..moveTo(daily.first.dx, daily.first.dy);
        for (final p in daily.skip(1)) {
          faint.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(
          faint,
          Paint()
            ..color = accent.withValues(alpha: 0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..strokeJoin = StrokeJoin.round,
        );
      }
      canvas.drawPath(
        line,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = average == null ? 2.5 : 3
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.restore();

    // The Today marker stays put; its dot fades in as the line reaches it.
    final todayPoint = main.isEmpty ? Offset(xAt(0), bottom) : main.last;
    final dot = ((clipX - todayPoint.dx + 12) / 12).clamp(0.0, 1.0);
    canvas
      ..drawLine(
        Offset(todayPoint.dx, _top - 4),
        Offset(todayPoint.dx, bottom),
        Paint()
          ..color = marker
          ..strokeWidth = 1,
      )
      ..drawCircle(
        todayPoint,
        4,
        Paint()..color = surface.withValues(alpha: surface.a * dot),
      )
      ..drawCircle(
        todayPoint,
        4,
        Paint()
          ..color = accent.withValues(alpha: accent.a * dot)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    paintLabel(canvas, 'Today', Offset(todayPoint.dx, 8), markerStyle);

    final quitIndex =
        (series.weekly
                ? quitDay.daysSince(series.start) ~/ 7
                : quitDay.daysSince(series.start))
            .clamp(0, math.max(points - 1, 0))
            .toInt();
    final quitX = xAt(quitIndex);
    canvas.drawPath(
      Path()
        ..moveTo(quitX, bottom)
        ..lineTo(quitX, bottom - 22)
        ..relativeLineTo(10, 0)
        ..relativeLineTo(-3, 4)
        ..relativeLineTo(3, 4)
        ..relativeLineTo(-10, 0),
      Paint()..color = flag,
    );
    paintLabel(
      canvas,
      'Quit ${AppFormat.monthDay(quitDay)}',
      Offset(quitX - 4, bottom - 32),
      flagStyle,
      align: TextAlign.right,
    );

    var lastLabelX = -100.0;
    var day = series.start;
    final last = quitDay.isAfter(series.end) ? quitDay : series.end;
    while (!day.isAfter(last)) {
      final offset = day.daysSince(series.start);
      final x = xAt(series.weekly ? offset ~/ 7 : offset);
      if (x - lastLabelX >= 36 && x <= right - 12) {
        paintLabel(
          canvas,
          AppFormat.monthDay(day).split(' ').first,
          Offset(x, size.height - 8),
          labelStyle,
          align: x == left ? TextAlign.left : TextAlign.center,
        );
        lastLabelX = x;
      }
      day = LogicalDay(day.year, day.month + 1, 1);
    }
  }

  @override
  bool shouldRepaint(_AllTimePainter old) => true;
}

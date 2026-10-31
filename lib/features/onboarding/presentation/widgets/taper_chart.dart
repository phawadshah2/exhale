import 'dart:math' as math;
import 'dart:ui';

import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_motion.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/home/presentation/widgets/history/chart_paint.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:flutter/material.dart';

/// The daily limit from today down to 0 on the quit day. The line travels
/// from today to the quit day when it appears and whenever the plan
/// changes, after [delay] (to let a sheet close first).
class TaperChart extends StatefulWidget {
  const TaperChart({required this.plan, this.delay = Duration.zero, super.key});

  final ReductionPlan plan;
  final Duration delay;

  static const double height = 150;

  /// The first draw waits for the step to slide in.
  static const Duration _entrance = Duration(milliseconds: 380);

  @override
  State<TaperChart> createState() => _TaperChartState();
}

class _TaperChartState extends State<TaperChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  late Animation<double> _reveal = _controller;

  void _play(Duration delay) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }
    final total = delay + AppMotion.fill;
    final start = delay.inMilliseconds / total.inMilliseconds;
    _controller.duration = total;
    _reveal = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: AppMotion.fillCurve),
    );
    _controller.forward(from: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.duration == null) _play(TaperChart._entrance);
  }

  @override
  void didUpdateWidget(TaperChart old) {
    super.didUpdateWidget(old);
    final a = old.plan;
    final b = widget.plan;
    if (a.quitDay != b.quitDay ||
        a.startDay != b.startDay ||
        a.startLimit != b.startLimit) {
      _play(widget.delay);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final colors = context.colors;
    final text = context.textTheme;
    final start = AppFormat.shortWeekdayDate(plan.startDay);
    final quit = AppFormat.shortWeekdayDate(plan.quitDay);
    return Semantics(
      label: '${plan.startLimit} today, 0 on $quit',
      excludeSemantics: true,
      child: SizedBox(
        height: TaperChart.height,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _TaperPainter(
              plan: plan,
              reveal: _reveal.value,
              startLabel: start,
              quitLabel: quit,
              line: context.exhale.emphasis,
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
      ),
    );
  }
}

class _TaperPainter extends CustomPainter {
  _TaperPainter({
    required this.plan,
    required this.reveal,
    required this.startLabel,
    required this.quitLabel,
    required this.line,
    required this.track,
    required this.surface,
    required this.valueStyle,
    required this.dateStyle,
  });

  final ReductionPlan plan;

  /// 0 shows only today's dot, 1 the whole line to the quit day.
  final double reveal;
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
    const top = 30.0;
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

    // The tip of the line, between two sampled points.
    final along = reveal.clamp(0.0, 1.0) * count;
    final last = along.floor().clamp(0, count);
    final tip = last >= count
        ? points.last
        : Offset.lerp(points[last], points[last + 1], along - last)!;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.sublist(1, last + 1)) {
      path.lineTo(point.dx, point.dy);
    }
    path.lineTo(tip.dx, tip.dy);
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
      final point = at((days * i / (_dots - 1)).round());
      if (point.dx <= tip.dx) canvas.drawCircle(point, 2.5, dot);
    }
    canvas.drawCircle(points.first, 5, Paint()..color = line);

    // The head rides the line, then becomes the hollow quit dot.
    final arrived = ((reveal - 0.92) / 0.08).clamp(0.0, 1.0);
    if (arrived < 1 && reveal > 0) {
      canvas.drawCircle(
        tip,
        4.5,
        Paint()..color = line.withValues(alpha: 1 - arrived),
      );
    }
    if (arrived > 0) {
      final radius = lerpDouble(3, 6, arrived)!;
      canvas
        ..drawCircle(
          points.last,
          radius,
          Paint()..color = surface.withValues(alpha: arrived),
        )
        ..drawCircle(
          points.last,
          radius,
          Paint()
            ..color = line.withValues(alpha: arrived)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
    }

    paintLabel(
      canvas,
      '${plan.startLimit} today',
      Offset(points.first.dx + 12, top - 18),
      valueStyle,
      align: TextAlign.left,
    );
    paintLabel(
      canvas,
      '0',
      Offset(right, baseline - 18),
      valueStyle.copyWith(
        color: valueStyle.color!.withValues(
          alpha: valueStyle.color!.a * arrived,
        ),
      ),
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
      old.reveal != reveal ||
      old.plan.startLimit != plan.startLimit ||
      old.plan.quitDay != plan.quitDay ||
      old.plan.startDay != plan.startDay ||
      old.line != line ||
      old.track != track ||
      old.surface != surface ||
      old.valueStyle != valueStyle ||
      old.dateStyle != dateStyle;
}

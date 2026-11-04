import 'dart:math' as math;

import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/plan/domain/services/plan_report.dart';
import 'package:exhale/features/plan/presentation/dot_layout.dart';
import 'package:exhale/features/plan/presentation/plan_copy.dart';
import 'package:exhale/features/plan/presentation/widgets/stage_ring.dart';
import 'package:exhale/features/tracking/domain/entities/daily_progress.dart';
import 'package:exhale/features/tracking/domain/entities/limit_status.dart';
import 'package:flutter/material.dart';

enum DayDot { under, atLimit, over, today, ahead }

/// A stage's days: a ring per day up to [maxRingDays], then a dot per day.
/// A stage that has ended has no today and no days ahead. Tapping a day up to
/// today calls [onDay].
class StageDays extends StatelessWidget {
  const StageDays({
    required this.report,
    required this.today,
    this.onDay,
    super.key,
  });

  /// The most days that still show as rings.
  static const int maxRingDays = 14;

  final StageReport report;
  final LogicalDay today;
  final ValueChanged<LogicalDay>? onDay;

  @override
  Widget build(BuildContext context) {
    final image = PlanCopy.daysImage(
      days: report.days,
      limit: report.stage.limit,
      over: report.daysOver,
      dayNumber: today.isAfter(report.lastDay)
          ? null
          : report.stage.dayNumberOf(today),
    );
    if (report.days > maxRingDays) {
      return _DayDots(
        report: report,
        today: today,
        semanticLabel: image,
        onDay: onDay,
      );
    }
    return Semantics(
      container: true,
      label: image,
      child: _DayRings(report: report, today: today, onDay: onDay),
    );
  }
}

Color _statusColor(BuildContext context, LimitStatus status) =>
    switch (status) {
      LimitStatus.under => context.colors.primaryContainer,
      LimitStatus.at => context.exhale.warning.solid,
      LimitStatus.over => context.exhale.danger.solid,
    };

/// Seven rings to a row. Fixed size, as the row above says the same thing.
class _DayRings extends StatelessWidget {
  const _DayRings({
    required this.report,
    required this.today,
    required this.onDay,
  });

  static const int _perRow = 7;
  static const double _ring = 40;

  final StageReport report;
  final LogicalDay today;
  final ValueChanged<LogicalDay>? onDay;

  @override
  Widget build(BuildContext context) {
    final byDay = {for (final day in report.daily) day.day: day};
    return MediaQuery.withNoTextScaling(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = math.min(_ring, constraints.maxWidth / _perRow);
          Widget ringFor(LogicalDay day) {
            final onDay = this.onDay;
            return StageDayRing(
              day: day,
              progress: day.isAfter(today) ? null : byDay[day],
              limit: report.stage.limit,
              isToday: day == today,
              size: size,
              onTap: onDay == null || day.isAfter(today)
                  ? null
                  : () => onDay(day),
            );
          }

          return Column(
            spacing: AppSpacing.xs,
            children: [
              for (var row = 0; row < report.days; row += _perRow)
                Row(
                  children: [
                    for (var i = row; i < row + _perRow; i++)
                      Expanded(
                        child: i < report.days
                            ? ringFor(report.stage.startDay.addDays(i))
                            : const SizedBox.shrink(),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

/// One day of a stage. With no [progress] the day is still ahead.
class StageDayRing extends StatelessWidget {
  const StageDayRing({
    required this.day,
    required this.progress,
    required this.limit,
    required this.isToday,
    required this.size,
    this.onTap,
    super.key,
  });

  final LogicalDay day;
  final DailyProgress? progress;
  final int limit;
  final bool isToday;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final progress = this.progress;
    final date = AppFormat.weekdayDate(day);
    final ring = Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      decoration: isToday
          ? BoxDecoration(
              color: context.exhale.inset,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            )
          : null,
      child: Column(
        spacing: 3,
        children: [
          SizedBox.square(
            dimension: size,
            child: CustomPaint(
              painter: StageRingPainter(
                fill: progress?.usedFraction ?? 0,
                strokeWidth: size / 11,
                color: progress == null
                    ? colors.primaryContainer
                    : _statusColor(context, progress.status),
                track: progress == null
                    ? colors.outlineVariant
                    : colors.surfaceContainerHighest,
                dashed: progress == null,
              ),
              child: Center(
                child: Text(
                  '${progress?.count ?? limit}',
                  style: text.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          Text(
            AppFormat.shortWeekday(day),
            style: text.labelSmall?.copyWith(
              color: isToday ? colors.onSurface : colors.onSurfaceVariant,
              fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
    return Semantics(
      container: true,
      button: onTap != null,
      label: progress == null
          ? '$date: limit $limit'
          : '$date: ${progress.count} of ${progress.limit}',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ring,
      ),
    );
  }
}

/// One dot per day, the start date above the first and the end date below.
class _DayDots extends StatelessWidget {
  const _DayDots({
    required this.report,
    required this.today,
    required this.semanticLabel,
    required this.onDay,
  });

  final StageReport report;
  final LogicalDay today;
  final String semanticLabel;
  final ValueChanged<LogicalDay>? onDay;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final small = context.textTheme.labelSmall?.copyWith(
      color: colors.onSurfaceVariant,
    );
    final byDay = {for (final day in report.daily) day.day: day};
    final dots = [
      for (var i = 0; i < report.days; i++)
        _dotFor(report.stage.startDay.addDays(i), byDay),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        Text(AppFormat.monthDay(report.stage.startDay), style: small),
        Semantics(
          container: true,
          image: true,
          label: semanticLabel,
          excludeSemantics: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final layout = DotLayout.of(
                days: report.days,
                width: constraints.maxWidth,
              );
              final onDay = this.onDay;
              final grid = SizedBox(
                height:
                    layout.rows * layout.size + (layout.rows - 1) * layout.gap,
                child: CustomPaint(
                  painter: DayDotsPainter(
                    dots: dots,
                    layout: layout,
                    under: colors.primaryContainer,
                    atLimit: context.exhale.warning.solid,
                    over: context.exhale.danger.solid,
                    ahead: colors.outlineVariant,
                  ),
                ),
              );
              if (onDay == null) return grid;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) {
                  final day = _dayAt(
                    details.localPosition,
                    layout,
                    constraints,
                  );
                  if (day != null) onDay(day);
                },
                child: grid,
              );
            },
          ),
        ),
        Row(
          spacing: AppSpacing.sm,
          children: [
            Expanded(
              child: Text(
                PlanCopy.eachDot,
                style: small?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Text(AppFormat.monthDay(report.lastDay), style: small),
          ],
        ),
      ],
    );
  }

  /// The day of the dot nearest [position], or null past the last day or
  /// after today.
  LogicalDay? _dayAt(
    Offset position,
    DotGrid layout,
    BoxConstraints constraints,
  ) {
    final across = layout.cols > 1
        ? (constraints.maxWidth - layout.size) / (layout.cols - 1)
        : 0.0;
    final col = across == 0
        ? 0
        : ((position.dx - layout.size / 2) / across).round().clamp(
            0,
            layout.cols - 1,
          );
    final row = (position.dy / (layout.size + layout.gap)).floor().clamp(
      0,
      layout.rows - 1,
    );
    final index = row * layout.cols + col;
    if (index >= report.days) return null;
    final day = report.stage.startDay.addDays(index);
    return day.isAfter(today) ? null : day;
  }

  DayDot _dotFor(LogicalDay day, Map<LogicalDay, DailyProgress> byDay) {
    if (day == today) return DayDot.today;
    if (day.isAfter(today)) return DayDot.ahead;
    return switch (byDay[day]?.status) {
      LimitStatus.at => DayDot.atLimit,
      LimitStatus.over => DayDot.over,
      _ => DayDot.under,
    };
  }
}

class DayDotsPainter extends CustomPainter {
  const DayDotsPainter({
    required this.dots,
    required this.layout,
    required this.under,
    required this.atLimit,
    required this.over,
    required this.ahead,
  });

  final List<DayDot> dots;
  final DotGrid layout;
  final Color under;
  final Color atLimit;
  final Color over;
  final Color ahead;

  @override
  void paint(Canvas canvas, Size size) {
    final dot = layout.size;
    final across = layout.cols > 1
        ? (size.width - dot) / (layout.cols - 1)
        : 0.0;
    final todayStroke = math.max(2, (dot * 0.3).roundToDouble()).toDouble();
    final aheadStroke = dot < 8 ? 1.0 : 1.5;

    for (final (index, kind) in dots.indexed) {
      final center = Offset(
        index % layout.cols * across + dot / 2,
        index ~/ layout.cols * (dot + layout.gap) + dot / 2,
      );
      switch (kind) {
        case DayDot.under:
          canvas.drawCircle(center, dot / 2, Paint()..color = under);
        case DayDot.atLimit:
          canvas.drawCircle(center, dot / 2, Paint()..color = atLimit);
        case DayDot.over:
          canvas.drawCircle(center, dot / 2, Paint()..color = over);
        case DayDot.today:
          _ring(canvas, center, dot, todayStroke, under);
        case DayDot.ahead:
          _ring(canvas, center, dot, aheadStroke, ahead);
      }
    }
  }

  void _ring(
    Canvas canvas,
    Offset center,
    double dot,
    double stroke,
    Color color,
  ) => canvas.drawCircle(
    center,
    (dot - stroke) / 2,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = color,
  );

  @override
  bool shouldRepaint(DayDotsPainter old) =>
      old.layout != layout ||
      old.under != under ||
      old.atLimit != atLimit ||
      old.over != over ||
      old.ahead != ahead ||
      !_sameDots(old.dots);

  bool _sameDots(List<DayDot> other) {
    if (other.length != dots.length) return false;
    for (var i = 0; i < dots.length; i++) {
      if (other[i] != dots[i]) return false;
    }
    return true;
  }
}

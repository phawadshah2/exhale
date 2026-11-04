import 'dart:math' as math;

import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_motion.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/home/presentation/widgets/history/chart_paint.dart';
import 'package:exhale/features/tracking/domain/entities/limit_status.dart';
import 'package:exhale/features/tracking/domain/entities/period_range.dart';
import 'package:exhale/features/tracking/domain/entities/period_summary.dart';
import 'package:exhale/features/tracking/presentation/limit_status_ui.dart';
import 'package:flutter/material.dart';

/// A month as a Monday-first calendar of day rings. Each ring fills toward
/// that day's limit.
class MonthRingCalendar extends StatelessWidget {
  const MonthRingCalendar({
    required this.summary,
    required this.onDayTap,
    super.key,
  });

  final PeriodSummary summary;
  final ValueChanged<LogicalDay> onDayTap;

  static const double _headerHeight = 24;
  static const double _rowHeight = 48;

  static const int _weeks = 6;

  /// Always six weeks tall, so swiping between months never changes the
  /// height. The days around the month belong to its neighbours.
  static double heightOf(PeriodRange range) =>
      _headerHeight + _weeks * _rowHeight;

  @override
  Widget build(BuildContext context) {
    final slots = summary.slots;
    final leading = summary.range.from.weekday - 1;
    final first = summary.range.from;
    final cells = <Object>[
      for (var i = leading; i > 0; i--) first.addDays(-i),
      ...slots,
    ];
    while (cells.length < _weeks * 7) {
      cells.add(first.addDays(cells.length - leading));
    }
    final label = context.textTheme.labelMedium!.copyWith(
      color: context.colors.onSurfaceVariant,
    );

    // Rings fill from empty, left to right and top to bottom.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.fill,
      curve: AppMotion.fillCurve,
      builder: (context, reveal, _) => _grid(cells, label, reveal),
    );
  }

  Widget _grid(List<Object> cells, TextStyle label, double reveal) {
    // The wave ends on the last shown day (today in this month), so its ring
    // finishes with the ring on the day card.
    final last = math.max(
      cells.lastIndexWhere((c) => c is DaySlot && c.kind != DaySlotKind.future),
      1,
    );
    return Column(
      children: [
        SizedBox(
          height: _headerHeight,
          child: Row(
            children: [
              for (final letter in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                Expanded(
                  child: Center(child: Text(letter, style: label)),
                ),
            ],
          ),
        ),
        for (var row = 0; row < cells.length ~/ 7; row++)
          SizedBox(
            height: _rowHeight,
            child: Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: switch (cells[row * 7 + col]) {
                      final LogicalDay day => _OutsideDay(day: day),
                      final DaySlot slot => _DayCell(
                        slot: slot,
                        onTap: onDayTap,
                        reveal: (reveal * 1.6 - (row * 7 + col) / last * 0.6)
                            .clamp(0.0, 1.0),
                      ),
                      _ => const SizedBox.shrink(),
                    },
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A day of the previous or next month: shown for context, never tapped.
class _OutsideDay extends StatelessWidget {
  const _OutsideDay({required this.day});

  final LogicalDay day;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Center(
      child: Text(
        '${day.day}',
        style: context.textTheme.labelSmall?.copyWith(
          color: context.colors.onSurfaceVariant.withValues(alpha: 0.35),
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.slot,
    required this.onTap,
    required this.reveal,
  });

  final DaySlot slot;
  final ValueChanged<LogicalDay> onTap;

  /// 0 to 1: how much of the ring is drawn while it animates in.
  final double reveal;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final progress = slot.progress;
    final count = slot.count;
    final future = slot.kind == DaySlotKind.future;
    final date = AppFormat.weekdayDate(slot.day);
    final semantics = progress != null
        ? '$date: ${progress.count} of ${progress.limit}'
        : count != null
        ? '$date: $count before your plan'
        : date;

    final numberColor = slot.isToday
        ? colors.primary
        : progress != null
        ? colors.onSurface
        : colors.onSurfaceVariant.withValues(alpha: 0.6);

    return Semantics(
      button: !future,
      label: semantics,
      excludeSemantics: true,
      onTap: future ? null : () => onTap(slot.day),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: future ? null : () => onTap(slot.day),
        child: Center(
          child: SizedBox.square(
            dimension: 36,
            child: CustomPaint(
              painter: _RingPainter(
                progress: progress == null
                    ? null
                    : (
                        fraction:
                            (progress.limit == 0 && progress.count == 0
                                ? 1.0
                                : progress.usedFraction) *
                            reveal,
                        color: progress.status.barColor(context),
                      ),
                dashed: future,
                track: colors.outlineVariant.withValues(alpha: 0.5),
                dash: colors.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              child: Center(
                child: Text(
                  '${slot.day.day}',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: numberColor,
                    fontWeight: slot.isToday
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.dashed,
    required this.track,
    required this.dash,
  });

  final ({double fraction, Color color})? progress;
  final bool dashed;
  final Color track;
  final Color dash;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: center, radius: 14);
    if (dashed) {
      canvas.drawPath(
        dashedPath(Path()..addOval(rect), dash: 0.1, gap: 4.4),
        Paint()
          ..color = dash
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 2,
      );
      return;
    }
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final arc = progress;
    if (arc == null || arc.fraction <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * arc.fraction,
      false,
      Paint()
        ..color = arc.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.dashed != dashed ||
      old.track != track ||
      old.dash != dash;
}

/// The colour key under the calendar.
class MonthRingKey extends StatelessWidget {
  const MonthRingKey({this.showBeforePlan = true, super.key});

  final bool showBeforePlan;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme.labelMedium?.copyWith(
      color: colors.onSurfaceVariant,
    );
    Widget item(String name, Color color, {bool ring = false}) => Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ring ? null : color,
            border: ring ? Border.all(color: color, width: 1.5) : null,
          ),
        ),
        Text(name, style: text),
      ],
    );
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      children: [
        item('Under', LimitStatus.under.barColor(context)),
        item('At limit', LimitStatus.at.barColor(context)),
        item('Over', LimitStatus.over.barColor(context)),
        if (showBeforePlan)
          item('Before plan', colors.outlineVariant, ring: true),
      ],
    );
  }
}

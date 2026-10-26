import 'dart:math' as math;

import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/home/presentation/widgets/history/chart_paint.dart';
import 'package:exhale/features/tracking/domain/entities/limit_status.dart';
import 'package:exhale/features/tracking/domain/entities/period_summary.dart';
import 'package:flutter/material.dart';

/// A week as a smooth line of daily counts against a dotted limit line.
/// Every day is a full-height tap column.
class WeekLineChart extends StatelessWidget {
  const WeekLineChart({
    required this.summary,
    required this.onDayTap,
    super.key,
  });

  final PeriodSummary summary;
  final ValueChanged<LogicalDay> onDayTap;

  static const double height = 186;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = context.textTheme.labelMedium!.copyWith(
      color: colors.onSurfaceVariant,
    );
    final slots = summary.slots;

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _WeekPainter(
              summary: summary,
              accent: colors.primaryContainer,
              warning: context.exhale.warning.solid,
              danger: context.exhale.danger.solid,
              neutral: colors.onSurfaceVariant,
              guide: colors.outlineVariant.withValues(alpha: 0.35),
              limitLine: colors.onSurface.withValues(alpha: 0.7),
              fillBase: colors.surfaceContainer,
              labelStyle: label,
              valueStyle: context.textTheme.labelMedium!.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
              overStyle: context.textTheme.labelMedium!.copyWith(
                color: context.exhale.danger.foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Row(
          children: [
            for (final slot in slots)
              Expanded(
                child: _DayColumn(
                  slot: slot,
                  onTap: slot.kind == DaySlotKind.future
                      ? null
                      : () => onDayTap(slot.day),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({required this.slot, required this.onTap});

  final DaySlot slot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final progress = slot.progress;
    final count = slot.count;
    final date = AppFormat.weekdayDate(slot.day);
    final label = progress != null
        ? '$date: ${progress.count} of ${progress.limit}'
        : count != null
        ? '$date: $count before your plan'
        : date;
    return Semantics(
      button: onTap != null,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _WeekPainter extends CustomPainter {
  const _WeekPainter({
    required this.summary,
    required this.accent,
    required this.warning,
    required this.danger,
    required this.neutral,
    required this.guide,
    required this.limitLine,
    required this.fillBase,
    required this.labelStyle,
    required this.valueStyle,
    required this.overStyle,
  });

  final PeriodSummary summary;
  final Color accent;
  final Color warning;
  final Color danger;
  final Color neutral;
  final Color guide;
  final Color limitLine;
  final Color fillBase;
  final TextStyle labelStyle;
  final TextStyle valueStyle;
  final TextStyle overStyle;

  static const double _top = 36;
  static const double _bottomInset = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final slots = summary.slots;
    final slotWidth = size.width / slots.length;
    final bottom = size.height - _bottomInset;
    final maxY = math.max(summary.peak, 1) * 1.25;
    double yFor(num value) => bottom - value / maxY * (bottom - _top);
    double xFor(int i) => (i + 0.5) * slotWidth;

    final guidePaint = Paint()
      ..color = guide
      ..strokeWidth = 1;
    for (var i = 0; i < slots.length; i++) {
      final x = xFor(i);
      paintLabel(
        canvas,
        AppFormat.weekdayInitial(slots[i].day),
        Offset(x, 10),
        labelStyle,
      );
      final line = Path()
        ..moveTo(x, 24)
        ..lineTo(x, bottom);
      canvas.drawPath(
        slots[i].kind == DaySlotKind.future
            ? dashedPath(line, dash: 3, gap: 3)
            : line,
        guidePaint..style = PaintingStyle.stroke,
      );
    }

    final limit = Path();
    int? previous;
    for (var i = 0; i < slots.length; i++) {
      final value = slots[i].limit;
      if (value == null) {
        previous = null;
        continue;
      }
      final y = yFor(value);
      final left = i * slotWidth;
      if (previous == null) {
        limit.moveTo(left, y);
      } else if (previous != value) {
        limit.lineTo(left, y);
      }
      limit.lineTo(left + slotWidth, y);
      previous = value;
    }
    canvas.drawPath(
      dashedPath(limit, dash: 2),
      Paint()
        ..color = limitLine
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
    final lastLimit = slots
        .lastWhere((s) => s.limit != null, orElse: () => slots.last)
        .limit;
    if (lastLimit != null) {
      paintLabel(
        canvas,
        'limit $lastLimit',
        Offset(size.width - 2, yFor(lastLimit) - 8),
        labelStyle.copyWith(fontSize: 10),
        align: TextAlign.right,
      );
    }

    final segments = <List<int>>[];
    for (var i = 0; i < slots.length; i++) {
      if (slots[i].count == null) continue;
      if (segments.isNotEmpty && segments.last.last == i - 1) {
        segments.last.add(i);
      } else {
        segments.add([i]);
      }
    }
    for (final segment in segments) {
      final points = [
        for (final i in segment) Offset(xFor(i), yFor(slots[i].count!)),
      ];
      if (points.length > 1) {
        final curve = smoothPath(points);
        final area = Path.from(curve)
          ..lineTo(points.last.dx, bottom)
          ..lineTo(points.first.dx, bottom)
          ..close();
        canvas
          ..drawPath(
            area,
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accent.withValues(alpha: 0.35),
                  accent.withValues(alpha: 0),
                ],
              ).createShader(Rect.fromLTWH(0, _top, size.width, bottom - _top)),
          )
          ..drawPath(
            curve,
            Paint()
              ..color = accent
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4
              ..strokeCap = StrokeCap.round,
          );
      }
    }

    for (var i = 0; i < slots.length; i++) {
      final slot = slots[i];
      final count = slot.count;
      final x = xFor(i);
      if (slot.kind == DaySlotKind.future) {
        canvas.drawCircle(
          Offset(x, bottom - 4),
          4,
          Paint()
            ..color = guide
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
        continue;
      }
      if (count == null) continue;
      final status = slot.progress?.status;
      final color = switch (status) {
        LimitStatus.under => accent,
        LimitStatus.at => warning,
        LimitStatus.over => danger,
        null => neutral,
      };
      final center = Offset(x, yFor(count));
      canvas
        ..drawCircle(center, 5, Paint()..color = fillBase)
        ..drawCircle(
          center,
          5,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      paintLabel(
        canvas,
        '$count',
        center.translate(0, -14),
        status == LimitStatus.over ? overStyle : valueStyle,
      );
    }
  }

  @override
  bool shouldRepaint(_WeekPainter old) => true;
}

import 'dart:math' as math;

import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/tracking/domain/entities/period_summary.dart';
import 'package:exhale/features/tracking/presentation/limit_status_ui.dart';
import 'package:flutter/material.dart';

/// Daily bars against a dashed, stepped limit line.
class HistoryChart extends StatelessWidget {
  const HistoryChart({
    required this.summary,
    required this.onDayTap,
    super.key,
  });

  final PeriodSummary summary;
  final ValueChanged<LogicalDay> onDayTap;

  static const double chartHeight = 168;
  static const double _labelHeight = 18;

  /// Space on the right for the "Limit" chip, clear of the bars.
  static const double _chipGutter = 64;

  @override
  Widget build(BuildContext context) {
    final slots = summary.slots;
    final isWeek = slots.length <= 7;
    final maxY = math.max(summary.peak, 1) * 1.25;
    double topFor(num value) => chartHeight - value / maxY * chartHeight;

    final currentLimit = slots
        .lastWhere(
          (s) => s.isToday,
          orElse: () =>
              slots.lastWhere((s) => s.limit != null, orElse: () => slots.last),
        )
        .limit;

    return LayoutBuilder(
      builder: (context, constraints) {
        final gutter = currentLimit == null ? 0.0 : _chipGutter;
        final slotWidth = (constraints.maxWidth - gutter) / slots.length;
        return Column(
          children: [
            SizedBox(
              height: chartHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    right: gutter,
                    child: CustomPaint(
                      painter: _GridAndLimitPainter(
                        limits: [for (final s in slots) s.limit],
                        maxY: maxY,
                        gridColor: context.colors.outlineVariant.withValues(
                          alpha: 0.25,
                        ),
                        lineColor: context.colors.primary.withValues(
                          alpha: 0.75,
                        ),
                      ),
                    ),
                  ),
                  for (var i = 0; i < slots.length; i++)
                    Positioned(
                      left: i * slotWidth,
                      width: slotWidth,
                      top: 0,
                      bottom: 0,
                      child: _BarSlot(
                        slot: slots[i],
                        slotWidth: slotWidth,
                        isWeek: isWeek,
                        heightFor: (value) => chartHeight - topFor(value),
                        onTap: slots[i].kind == DaySlotKind.tracked
                            ? () => onDayTap(slots[i].day)
                            : null,
                      ),
                    ),
                  if (currentLimit != null)
                    Positioned(
                      right: 0,
                      width: gutter - 6,
                      top: (topFor(currentLimit) - 11).clamp(
                        0,
                        chartHeight - 22,
                      ),
                      child: _LimitChip(limit: currentLimit),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: _labelHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var i = 0; i < slots.length; i++)
                    if (isWeek || (slots[i].day.day - 1) % 7 == 0)
                      Positioned(
                        left: i * slotWidth - (isWeek ? 0 : 10),
                        width: isWeek ? slotWidth : slotWidth + 20,
                        child: _DayLabel(
                          text: isWeek
                              ? AppFormat.weekdayInitial(slots[i].day)
                              : '${slots[i].day.day}',
                          highlighted: slots[i].isToday,
                        ),
                      ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BarSlot extends StatelessWidget {
  const _BarSlot({
    required this.slot,
    required this.slotWidth,
    required this.isWeek,
    required this.heightFor,
    required this.onTap,
  });

  final DaySlot slot;
  final double slotWidth;
  final bool isWeek;
  final double Function(num value) heightFor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final barWidth = math.min<double>(slotWidth * (isWeek ? 0.58 : 0.62), 34);
    final radius = Radius.circular(isWeek ? 8 : 3);
    final progress = slot.progress;

    final Widget bar;
    if (slot.kind == DaySlotKind.future) {
      bar = isWeek
          ? CustomPaint(
              size: Size(barWidth, 22),
              painter: _DashedBoxPainter(
                color: context.colors.outlineVariant,
                radius: radius,
              ),
            )
          : const SizedBox.shrink();
    } else if (progress == null) {
      bar = const SizedBox.shrink();
    } else if (progress.count == 0) {
      bar = Container(
        width: barWidth,
        height: 3,
        decoration: BoxDecoration(
          color: context.colors.outlineVariant,
          borderRadius: BorderRadius.all(radius),
        ),
      );
    } else {
      final color = progress.status.barColor(context);
      bar = TweenAnimationBuilder<double>(
        tween: Tween(end: heightFor(progress.count)),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, height, _) => Container(
          width: barWidth,
          height: height,
          decoration: BoxDecoration(
            color: slot.isToday ? color : color.withValues(alpha: 0.82),
            borderRadius: BorderRadius.vertical(top: radius),
            boxShadow: slot.isToday
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.18),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        ),
      );
    }

    final label = progress == null
        ? null
        : '${AppFormat.weekdayDate(slot.day)}: '
              '${progress.count} of ${progress.limit}';

    return Semantics(
      button: onTap != null,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (isWeek && progress != null && progress.count > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${progress.count}',
                  style: context.textTheme.labelMedium?.copyWith(
                    color: slot.isToday
                        ? context.colors.onSurface
                        : context.colors.onSurfaceVariant,
                  ),
                ),
              ),
            bar,
          ],
        ),
      ),
    );
  }
}

class _DayLabel extends StatelessWidget {
  const _DayLabel({required this.text, required this.highlighted});

  final String text;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: context.textTheme.labelMedium?.copyWith(
        color: highlighted
            ? context.colors.primary
            : context.colors.onSurfaceVariant,
        fontWeight: highlighted ? FontWeight.w700 : null,
      ),
    );
  }
}

class _LimitChip extends StatelessWidget {
  const _LimitChip({required this.limit});

  final int limit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: 22,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: colors.surfaceContainerHighest,
        shape: StadiumBorder(
          side: BorderSide(color: colors.primary.withValues(alpha: 0.5)),
        ),
      ),
      child: Text(
        'Limit $limit',
        style: context.textTheme.labelMedium?.copyWith(color: colors.primary),
      ),
    );
  }
}

class _GridAndLimitPainter extends CustomPainter {
  const _GridAndLimitPainter({
    required this.limits,
    required this.maxY,
    required this.gridColor,
    required this.lineColor,
  });

  final List<int?> limits;
  final double maxY;
  final Color gridColor;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final f in const [0.25, 0.5, 0.75, 1.0]) {
      final y = size.height * f;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final slotWidth = size.width / limits.length;
    double yFor(int value) => size.height - value / maxY * size.height;

    final path = Path();
    int? previous;
    for (var i = 0; i < limits.length; i++) {
      final limit = limits[i];
      if (limit == null) {
        previous = null;
        continue;
      }
      final y = yFor(limit);
      final left = i * slotWidth;
      if (previous == null) {
        path.moveTo(left, y);
      } else if (previous != limit) {
        path.lineTo(left, y);
      }
      path.lineTo(left + slotWidth, y);
      previous = limit;
    }

    canvas.drawPath(
      _dashed(path),
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  static Path _dashed(Path source, {double dash = 6, double gap = 4}) {
    final out = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        out.addPath(metric.extractPath(distance, distance + dash), Offset.zero);
        distance += dash + gap;
      }
    }
    return out;
  }

  @override
  bool shouldRepaint(_GridAndLimitPainter old) =>
      old.maxY != maxY ||
      old.gridColor != gridColor ||
      old.lineColor != lineColor ||
      !_sameLimits(old.limits, limits);

  static bool _sameLimits(List<int?> a, List<int?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class _DashedBoxPainter extends CustomPainter {
  const _DashedBoxPainter({required this.color, required this.radius});

  final Color color;
  final Radius radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, radius);
    canvas.drawPath(
      _GridAndLimitPainter._dashed(Path()..addRRect(rrect), dash: 4, gap: 3),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_DashedBoxPainter old) =>
      old.color != color || old.radius != radius;
}

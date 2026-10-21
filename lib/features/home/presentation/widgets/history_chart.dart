import 'dart:math' as math;

import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/tracking/domain/entities/period_summary.dart';
import 'package:exhale/features/tracking/presentation/limit_status_ui.dart';
import 'package:flutter/material.dart';

/// Daily bars against a dashed, stepped limit line, spread across the full
/// width. [selected] is highlighted; tapping a bar selects its day.
class HistoryChart extends StatelessWidget {
  const HistoryChart({
    required this.summary,
    required this.selected,
    required this.canSelect,
    required this.onSelect,
    super.key,
  });

  final PeriodSummary summary;
  final LogicalDay selected;
  final bool Function(LogicalDay day) canSelect;
  final ValueChanged<LogicalDay> onSelect;

  static const double chartHeight = 168;
  static const double _labelHeight = 18;

  /// Bars plus day labels.
  static const double height = chartHeight + 8 + _labelHeight;

  /// Bars keep the width they had when 64pt on the right held the limit
  /// chip, now that the chart uses the full width.
  static const double _barWidthInset = 64;

  @override
  Widget build(BuildContext context) {
    final slots = summary.slots;
    final isWeek = slots.length <= 7;
    final maxY = math.max(summary.peak, 1) * 1.25;
    double topFor(num value) => chartHeight - value / maxY * chartHeight;

    final shownLimit = slots
        .lastWhere(
          (s) => s.day == selected && s.limit != null,
          orElse: () =>
              slots.lastWhere((s) => s.limit != null, orElse: () => slots.last),
        )
        .limit;

    return LayoutBuilder(
      builder: (context, constraints) {
        final slotWidth = constraints.maxWidth / slots.length;
        final barWidth = math.min<double>(
          (constraints.maxWidth - _barWidthInset) /
              slots.length *
              (isWeek ? 0.58 : 0.62),
          34,
        );
        return Column(
          children: [
            SizedBox(
              height: chartHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
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
                    if (slots[i].day == selected)
                      Positioned(
                        left: i * slotWidth + (isWeek ? 4 : 0),
                        width: slotWidth - (isWeek ? 8 : 0),
                        top: 0,
                        bottom: 0,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: context.colors.primary.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius: BorderRadius.circular(
                              isWeek ? 10 : 3,
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
                        barWidth: barWidth,
                        isWeek: isWeek,
                        isSelected: slots[i].day == selected,
                        heightFor: (value) => chartHeight - topFor(value),
                        onTap:
                            slots[i].kind != DaySlotKind.future &&
                                canSelect(slots[i].day)
                            ? () => onSelect(slots[i].day)
                            : null,
                      ),
                    ),
                  if (shownLimit != null)
                    Positioned(
                      left: 0,
                      top: (topFor(shownLimit) - 18).clamp(0, chartHeight - 16),
                      child: IgnorePointer(
                        child: _LimitLabel(limit: shownLimit),
                      ),
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
                          highlighted: slots[i].day == selected,
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
    required this.barWidth,
    required this.isWeek,
    required this.isSelected,
    required this.heightFor,
    required this.onTap,
  });

  final DaySlot slot;
  final double barWidth;
  final bool isWeek;
  final bool isSelected;
  final double Function(num value) heightFor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = Radius.circular(isWeek ? 8 : 3);
    final progress = slot.progress;
    final count = slot.count;

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
    } else if (count == null) {
      bar = const SizedBox.shrink();
    } else if (count == 0) {
      bar = Container(
        width: barWidth,
        height: 3,
        decoration: BoxDecoration(
          color: context.colors.outlineVariant,
          borderRadius: BorderRadius.all(radius),
        ),
      );
    } else {
      final color =
          progress?.status.barColor(context) ??
          context.colors.onSurfaceVariant.withValues(alpha: 0.45);
      bar = TweenAnimationBuilder<double>(
        tween: Tween(end: heightFor(count)),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, height, _) => Container(
          width: barWidth,
          height: height,
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.82),
            borderRadius: BorderRadius.vertical(top: radius),
            boxShadow: isSelected && progress != null
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

    final label = progress != null
        ? '${AppFormat.weekdayDate(slot.day)}: '
              '${progress.count} of ${progress.limit}'
        : count != null
        ? '${AppFormat.weekdayDate(slot.day)}: $count before your plan'
        : null;

    return Semantics(
      button: onTap != null,
      selected: isSelected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (isWeek && count != null && count > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '$count',
                  style: context.textTheme.labelMedium?.copyWith(
                    color: isSelected
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

class _LimitLabel extends StatelessWidget {
  const _LimitLabel({required this.limit});

  final int limit;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Limit $limit',
      style: context.textTheme.labelSmall?.copyWith(
        color: context.colors.primary,
        fontWeight: FontWeight.w600,
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

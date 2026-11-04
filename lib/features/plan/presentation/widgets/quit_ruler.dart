import 'dart:async';

import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/plan/domain/validation/plan_validation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Where a ruler's ticks and month names go, in days from today.
@immutable
class RulerLayout {
  const RulerLayout({required this.today, required this.spanDays});

  final LogicalDay today;
  final int spanDays;

  static const int _weeklyUpToDays = 40 * 7;

  /// Month names closer than this would touch, so the later one is dropped.
  static const double minMonthGap = 30;

  int get tickEveryDays => spanDays <= _weeklyUpToDays ? 7 : 28;

  List<({int days, bool tall})> get ticks => [
    for (var days = 0; days <= spanDays; days += tickEveryDays)
      (days: days, tall: days % 28 == 0),
  ];

  /// The first days of months on the ruler, for a ruler [width] points wide.
  List<({int days, String name})> months({required double width}) {
    final found = <({int days, String name})>[];
    double? lastX;
    var first = today.startOfMonth;
    if (first != today) first = first.addDays(first.daysInMonth);
    while (first.daysSince(today) <= spanDays) {
      final days = first.daysSince(today);
      final x = days / spanDays * width;
      if (lastX == null || x - lastX >= minMonthGap) {
        found.add((days: days, name: AppFormat.shortMonth(first)));
        lastX = x;
      }
      first = first.addDays(first.daysInMonth);
    }
    return found;
  }
}

/// Picks a quit date by dragging along a ruler that starts today.
class QuitRuler extends StatefulWidget {
  const QuitRuler({
    required this.today,
    required this.selected,
    required this.spanDays,
    required this.onChanged,
    super.key,
  });

  final LogicalDay today;
  final LogicalDay selected;
  final int spanDays;
  final ValueChanged<LogicalDay> onChanged;

  @override
  State<QuitRuler> createState() => _QuitRulerState();
}

class _QuitRulerState extends State<QuitRuler> {
  /// The day the last drag event gave, ahead of the page's rebuild.
  LogicalDay? _dragDay;

  int get _earliest => PlanValidation.minPlanDays;

  void _drag(Offset position) {
    final width = context.size!.width;
    final days = (position.dx / width * widget.spanDays).round().clamp(
      _earliest,
      widget.spanDays,
    );
    final last = _dragDay ?? widget.selected;
    final next = widget.today.addDays(days);
    if (next == last) return;
    final every = RulerLayout(
      today: widget.today,
      spanDays: widget.spanDays,
    ).tickEveryDays;
    if (days ~/ every != last.daysSince(widget.today) ~/ every) {
      unawaited(HapticFeedback.selectionClick());
    }
    _dragDay = next;
    widget.onChanged(next);
  }

  void _end() => _dragDay = null;

  String _semanticValue(LogicalDay day) {
    final away = day.daysSince(widget.today);
    final unit = away == 1 ? 'day' : 'days';
    return '${AppFormat.monthDay(day)}, $away $unit away';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selected = widget.selected;
    final days = selected.daysSince(widget.today);
    final later = selected.addDays(1);
    final earlier = selected.addDays(-1);
    final canIncrease = days < widget.spanDays;
    final canDecrease = days > _earliest;

    return Semantics(
      slider: true,
      label: 'Quit date',
      value: _semanticValue(selected),
      increasedValue: canIncrease ? _semanticValue(later) : null,
      decreasedValue: canDecrease ? _semanticValue(earlier) : null,
      onIncrease: canIncrease ? () => widget.onChanged(later) : null,
      onDecrease: canDecrease ? () => widget.onChanged(earlier) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        dragStartBehavior: DragStartBehavior.down,
        onHorizontalDragStart: (details) => _drag(details.localPosition),
        onHorizontalDragUpdate: (details) => _drag(details.localPosition),
        onHorizontalDragEnd: (_) => _end(),
        onHorizontalDragCancel: _end,
        child: CustomPaint(
          size: const Size(double.infinity, _RulerPainter.height),
          painter: _RulerPainter(
            layout: RulerLayout(today: widget.today, spanDays: widget.spanDays),
            selectedDays: days,
            active: colors.primaryContainer,
            rest: colors.outlineVariant,
            label: context.textTheme.labelSmall!.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  const _RulerPainter({
    required this.layout,
    required this.selectedDays,
    required this.active,
    required this.rest,
    required this.label,
  });

  final RulerLayout layout;
  final int selectedDays;
  final Color active;
  final Color rest;
  final TextStyle label;

  static const double height = 52;
  static const double _tickBottom = 34;
  static const double _tall = 26;
  static const double _short = 14;
  static const double _tickWidth = 2;
  static const double _markerWidth = 4;
  static const double _markerHeight = 38;

  @override
  void paint(Canvas canvas, Size size) {
    final span = layout.spanDays;
    double xOf(int days) => days / span * size.width;

    for (final tick in layout.ticks) {
      final x = xOf(tick.days)
          .clamp(_tickWidth / 2, size.width - _tickWidth / 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            x - _tickWidth / 2,
            _tickBottom - (tick.tall ? _tall : _short),
            x + _tickWidth / 2,
            _tickBottom,
          ),
          const Radius.circular(1),
        ),
        Paint()..color = tick.days <= selectedDays ? active : rest,
      );
    }

    final markerX = xOf(selectedDays)
        .clamp(_markerWidth / 2, size.width - _markerWidth / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          markerX - _markerWidth / 2,
          0,
          _markerWidth,
          _markerHeight,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = active,
    );

    for (final month in layout.months(width: size.width)) {
      final painter = TextPainter(
        text: TextSpan(text: month.name, style: label),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = (xOf(month.days) - painter.width / 2).clamp(
        0.0,
        size.width - painter.width,
      );
      painter
        ..paint(canvas, Offset(x, height - painter.height))
        ..dispose();
    }
  }

  @override
  bool shouldRepaint(_RulerPainter old) =>
      old.layout.today != layout.today ||
      old.layout.spanDays != layout.spanDays ||
      old.selectedDays != selectedDays ||
      old.active != active ||
      old.rest != rest ||
      old.label != label;
}

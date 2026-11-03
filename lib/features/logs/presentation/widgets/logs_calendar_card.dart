import 'dart:async';

import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/home/presentation/widgets/history/month_ring_calendar.dart';
import 'package:exhale/features/logs/domain/logs_selection.dart';
import 'package:exhale/features/logs/presentation/providers/logs_providers.dart';
import 'package:exhale/features/logs/presentation/widgets/logs_date_picker.dart';
import 'package:exhale/features/plan/presentation/widgets/stage_ring.dart';
import 'package:exhale/features/tracking/domain/entities/period_range.dart';
import 'package:exhale/features/tracking/presentation/limit_status_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The week's arrows, a title that opens a calendar, and a ring for each day.
class LogsCalendarCard extends StatefulWidget {
  const LogsCalendarCard({
    required this.selection,
    required this.view,
    required this.today,
    required this.earliest,
    required this.onChanged,
    super.key,
  });

  final LogsSelection selection;
  final LogsView view;
  final LogicalDay today;
  final LogicalDay earliest;
  final ValueChanged<LogsSelection> onChanged;

  /// This week, Last week, or 3 weeks ago.
  static String ago(LogsSelection selection, LogicalDay today) {
    final back = ChartPeriod.week.periodsBetween(selection.period.from, today);
    return switch (back) {
      0 => 'This week',
      1 => 'Last week',
      _ => '$back weeks ago',
    };
  }

  @override
  State<LogsCalendarCard> createState() => _LogsCalendarCardState();
}

class _LogsCalendarCardState extends State<LogsCalendarCard> {
  void _change(LogsSelection selection) {
    unawaited(HapticFeedback.selectionClick());
    widget.onChanged(selection);
  }

  String get _title {
    final PeriodRange(:from, :to) = widget.selection.period;
    return '${AppFormat.monthDay(from)} – ${AppFormat.monthDay(to)}';
  }

  Future<void> _pickDay() async {
    final day = await showLogsDatePicker(
      context,
      selected: widget.selection.selected,
      earliest: widget.earliest,
      today: widget.today,
    );
    if (day != null && mounted) _change(widget.selection.select(day));
  }

  /// Swiping right goes to the week before, as in History.
  void _swipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final selection = widget.selection;
    if (velocity > 200 && selection.canGoEarlier(widget.earliest)) {
      _change(selection.step(-1, today: widget.today));
    } else if (velocity < -200 && selection.canGoLater(widget.today)) {
      _change(selection.step(1, today: widget.today));
    }
  }

  @override
  Widget build(BuildContext context) {
    final selection = widget.selection;
    final today = widget.today;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.gutterSm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.sm,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Earlier',
                  onPressed: selection.canGoEarlier(widget.earliest)
                      ? () => _change(selection.step(-1, today: today))
                      : null,
                  icon: const Icon(AppIcons.back, size: 18),
                ),
                Expanded(
                  child: _Title(
                    title: _title,
                    subtitle: LogsCalendarCard.ago(selection, today),
                    onTap: () => unawaited(_pickDay()),
                  ),
                ),
                IconButton(
                  tooltip: 'Later',
                  onPressed: selection.canGoLater(today)
                      ? () => _change(selection.step(1, today: today))
                      : null,
                  icon: const Icon(AppIcons.chevronRight, size: 18),
                ),
              ],
            ),
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragEnd: _swipe,
              child: _Grid(
                selection: selection,
                view: widget.view,
                today: today,
                earliest: widget.earliest,
                onSelect: (day) => _change(selection.select(day)),
              ),
            ),
            const Center(child: MonthRingKey(showBeforePlan: false)),
          ],
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return Semantics(
      button: true,
      label: 'Pick a day',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.xs,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(AppIcons.chevronDown, size: 14),
                ],
              ),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: text.labelMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({
    required this.selection,
    required this.view,
    required this.today,
    required this.earliest,
    required this.onSelect,
  });

  final LogsSelection selection;
  final LogsView view;
  final LogicalDay today;
  final LogicalDay earliest;
  final ValueChanged<LogicalDay> onSelect;

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final period = selection.period;
    final cells = <LogicalDay?>[
      for (var i = 1; i < period.from.weekday; i++) null,
      ...period.days,
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    return Column(
      children: [
        // Seven of these share a phone's width; past this scale "Wed" doesn't
        // fit its column.
        MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.5,
          child: ExcludeSemantics(
            child: Row(
              children: [
                for (final weekday in _weekdays)
                  Expanded(
                    child: Text(
                      weekday,
                      textAlign: TextAlign.center,
                      style: context.textTheme.labelSmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        for (var row = 0; row < cells.length ~/ 7; row++)
          Row(
            children: [
              for (final day in cells.sublist(row * 7, row * 7 + 7))
                Expanded(
                  child: day == null
                      ? const SizedBox(height: _DayCell.height)
                      : _DayCell(
                          key: ValueKey(day),
                          day: day,
                          entry: view.dayOf(day),
                          selected: day == selection.selected,
                          isToday: day == today,
                          enabled:
                              !day.isAfter(today) && !day.isBefore(earliest),
                          onTap: () => onSelect(day),
                        ),
                ),
            ],
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.entry,
    required this.selected,
    required this.isToday,
    required this.enabled,
    required this.onTap,
    super.key,
  });

  static const double height = 48;
  static const double _ring = 38;
  static const double _stroke = 3.5;

  final LogicalDay day;
  final LogsDay entry;
  final bool selected;
  final bool isToday;
  final bool enabled;
  final VoidCallback onTap;

  String get _label {
    final date = AppFormat.monthDay(day);
    final limit = entry.limit;
    if (limit != null) return '$date, ${entry.count} of $limit';
    return entry.count > 0 ? '$date, ${entry.count} logged' : date;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final exhale = context.exhale;
    final progress = entry.progress;
    final atZero = progress?.limit == 0 && progress?.count == 0;

    final ringColor = atZero
        ? exhale.success.solid
        : progress?.status.barColor(context) ?? colors.outlineVariant;
    final dateColor = enabled
        ? colors.onSurface
        : colors.onSurfaceVariant.withValues(alpha: 0.6);

    return Semantics(
      button: enabled,
      enabled: enabled,
      selected: selected,
      label: _label,
      excludeSemantics: true,
      onTap: enabled ? onTap : null,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: height,
          alignment: Alignment.center,
          // The current-stage highlight on Plan details.
          decoration: selected
              ? BoxDecoration(
                  color: exhale.inset,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                )
              : null,
          child: SizedBox.square(
            dimension: _ring,
            child: CustomPaint(
              painter: StageRingPainter(
                fill: atZero ? 1 : progress?.usedFraction ?? 0,
                strokeWidth: _stroke,
                color: ringColor,
                track: progress == null
                    ? colors.outlineVariant
                    : selected
                    ? colors.surfaceContainerHighest
                    : colors.surfaceContainerHigh,
                dashed: progress == null,
              ),
              child: Center(
                child: MediaQuery.withNoTextScaling(
                  child: Text(
                    '${day.day}',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: dateColor,
                      fontWeight: selected || isToday
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
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

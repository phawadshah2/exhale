import 'dart:async';

import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/pill_segmented_control.dart';
import 'package:exhale/features/home/presentation/widgets/history/month_ring_calendar.dart';
import 'package:exhale/features/logs/domain/logs_selection.dart';
import 'package:exhale/features/logs/presentation/providers/logs_providers.dart';
import 'package:exhale/features/plan/presentation/widgets/stage_ring.dart';
import 'package:exhale/features/tracking/domain/entities/period_range.dart';
import 'package:exhale/features/tracking/presentation/limit_status_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Week and Month, the arrows, the month chips and a ring for each day.
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

  /// This week, Last week, 3 weeks ago, or the same in months.
  static String ago(LogsSelection selection, LogicalDay today) {
    final mode = selection.mode;
    final name = mode == LogsMode.week ? 'week' : 'month';
    final back = mode.unit.periodsBetween(selection.period.from, today);
    return switch (back) {
      0 => 'This $name',
      1 => 'Last $name',
      _ => '$back ${name}s ago',
    };
  }

  @override
  State<LogsCalendarCard> createState() => _LogsCalendarCardState();
}

class _LogsCalendarCardState extends State<LogsCalendarCard> {
  bool _picking = false;

  void _change(LogsSelection selection) {
    unawaited(HapticFeedback.selectionClick());
    widget.onChanged(selection);
  }

  String get _title {
    final PeriodRange(:from, :to) = widget.selection.period;
    return widget.selection.mode == LogsMode.week
        ? '${AppFormat.monthDay(from)} – ${AppFormat.monthDay(to)}'
        : AppFormat.monthYear(from);
  }

  List<LogicalDay> get _months => [
    for (
      var month = widget.earliest.startOfMonth;
      !month.isAfter(widget.today);
      month = LogicalDay(month.year, month.month + 1, 1)
    )
      month,
  ];

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
            PillSegmentedControl<LogsMode>(
              selected: selection.mode,
              onChanged: (mode) => widget.onChanged(selection.withMode(mode)),
              segments: const [
                PillSegment(value: LogsMode.week, label: 'Week'),
                PillSegment(value: LogsMode.month, label: 'Month'),
              ],
            ),
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
                    open: _picking,
                    onTap: () => setState(() => _picking = !_picking),
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
            if (_picking)
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final month in _months)
                    _MonthChip(
                      label: '${AppFormat.shortMonth(month)} ${month.year}',
                      selected:
                          selection.mode == LogsMode.month &&
                          selection.period.from == month,
                      onTap: () {
                        setState(() => _picking = false);
                        _change(selection.pickMonth(month, today: today));
                      },
                    ),
                ],
              ),
            _Grid(
              selection: selection,
              view: widget.view,
              today: today,
              earliest: widget.earliest,
              onSelect: (day) => _change(selection.select(day)),
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
    required this.open,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return Semantics(
      button: true,
      expanded: open,
      label: 'Choose a month',
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
                  Icon(
                    open ? AppIcons.chevronUp : AppIcons.chevronDown,
                    size: 14,
                  ),
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

class _MonthChip extends StatelessWidget {
  const _MonthChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final exhale = context.exhale;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: ShapeDecoration(
            color: selected ? exhale.emphasis : null,
            shape: StadiumBorder(
              side: BorderSide(
                color: selected ? exhale.emphasis : colors.outlineVariant,
              ),
            ),
          ),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: context.textTheme.labelMedium?.copyWith(
                color: selected ? exhale.onEmphasis : colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
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

    final ringColor = selected
        ? exhale.onEmphasis
        : atZero
        ? exhale.success.solid
        : progress?.status.barColor(context) ?? colors.outlineVariant;
    final dateColor = selected
        ? exhale.onEmphasis
        : enabled
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
          decoration: selected
              ? BoxDecoration(
                  color: exhale.emphasis,
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
                track: selected
                    ? exhale.onEmphasis.withValues(alpha: 0.35)
                    : progress == null
                    ? colors.outlineVariant
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

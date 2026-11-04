import 'dart:async';

import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_motion.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/app_dialogs.dart';
import 'package:exhale/core/widgets/smooth_switcher.dart';
import 'package:exhale/features/home/presentation/widgets/history/month_ring_calendar.dart';
import 'package:exhale/features/logs/domain/logs_selection.dart';
import 'package:exhale/features/logs/presentation/providers/logs_providers.dart';
import 'package:exhale/features/plan/presentation/widgets/stage_ring.dart';
import 'package:exhale/features/tracking/domain/entities/period_range.dart';
import 'package:exhale/features/tracking/presentation/limit_status_ui.dart';
import 'package:flutter/cupertino.dart' show CupertinoDatePickerMode;
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
    if (selection.isRange) return range(selection.period);
    final back = ChartPeriod.week.periodsBetween(selection.period.from, today);
    return switch (back) {
      0 => 'This week',
      1 => 'Last week',
      _ => '$back weeks ago',
    };
  }

  /// Oct 1 – Oct 31
  static String range(PeriodRange period) =>
      '${AppFormat.monthDay(period.from)} – ${AppFormat.monthDay(period.to)}';

  @override
  State<LogsCalendarCard> createState() => _LogsCalendarCardState();
}

class _LogsCalendarCardState extends State<LogsCalendarCard> {
  void _change(LogsSelection selection) {
    unawaited(HapticFeedback.selectionClick());
    widget.onChanged(selection);
  }

  String get _title => LogsCalendarCard.range(widget.selection.period);

  Future<void> _pickDay() async {
    final picked = await showWheelPicker(
      context,
      title: 'Pick a day',
      mode: CupertinoDatePickerMode.date,
      initial: widget.selection.selected.toLocalDate(),
      minimum: widget.earliest.toLocalDate(),
      maximum: widget.today.toLocalDate(),
    );
    if (picked != null && mounted) {
      _change(widget.selection.select(LogicalDay.fromDate(picked)));
    }
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

    if (selection.isRange) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.gutterSm),
          child: _RangeHeader(
            title: _title,
            onBack: () => _change(selection.select(selection.period.to)),
          ),
        ),
      );
    }

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
              child: SmoothSwitcher(
                resize: true,
                child: _Grid(
                  key: ValueKey('grid-${selection.period.from}'),
                  selection: selection,
                  view: widget.view,
                  today: today,
                  earliest: widget.earliest,
                  onSelect: (day) => _change(selection.select(day)),
                ),
              ),
            ),
            const Center(child: MonthRingKey(showBeforePlan: false)),
          ],
        ),
      ),
    );
  }
}

/// The range opened from History, with a way back to the weeks.
class _RangeHeader extends StatelessWidget {
  const _RangeHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final colors = context.colors;
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        Semantics(
          button: true,
          label: 'Back to weeks',
          excludeSemantics: true,
          onTap: onBack,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onBack,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Center(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Whole range · ',
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                      TextSpan(
                        text: 'Back to weeks',
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  style: text.labelMedium,
                ),
              ),
            ),
          ),
        ),
      ],
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
    super.key,
  });

  final LogsSelection selection;
  final LogsView view;
  final LogicalDay today;
  final LogicalDay earliest;
  final ValueChanged<LogicalDay> onSelect;

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

  static const double height = 68;
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
        child: AnimatedContainer(
          duration: AppMotion.swap,
          curve: AppMotion.swapCurve,
          height: height,
          alignment: Alignment.center,
          // The current-stage highlight on Plan details.
          decoration: BoxDecoration(
            color: selected ? exhale.inset : exhale.inset.withValues(alpha: 0),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 3,
            children: [
              // Seven of these share a phone's width; past this scale "Wed"
              // doesn't fit its column.
              MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.5,
                child: Text(
                  AppFormat.shortWeekday(day),
                  style: context.textTheme.labelSmall?.copyWith(
                    color: selected || isToday
                        ? colors.onSurface
                        : colors.onSurfaceVariant,
                    fontWeight: selected || isToday
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
              ),
              SizedBox.square(
                dimension: _ring,
                // The track eases between its two colours with the highlight.
                child: TweenAnimationBuilder<Color?>(
                  tween: ColorTween(
                    end: progress == null
                        ? colors.outlineVariant
                        : selected
                        ? colors.surfaceContainerHighest
                        : colors.surfaceContainerHigh,
                  ),
                  duration: AppMotion.swap,
                  curve: AppMotion.swapCurve,
                  builder: (context, track, child) => CustomPaint(
                    painter: StageRingPainter(
                      fill: atZero ? 1 : progress?.usedFraction ?? 0,
                      strokeWidth: _stroke,
                      color: ringColor,
                      track: track ?? colors.surfaceContainerHigh,
                      dashed: progress == null,
                    ),
                    child: child,
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
            ],
          ),
        ),
      ),
    );
  }
}

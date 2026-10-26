import 'dart:async';

import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/pill_segmented_control.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/presentation/habit_wording.dart';
import 'package:exhale/features/home/presentation/providers/home_providers.dart';
import 'package:exhale/features/home/presentation/widgets/backward_pager.dart';
import 'package:exhale/features/home/presentation/widgets/history_chart.dart';
import 'package:exhale/features/tracking/domain/entities/period_range.dart';
import 'package:exhale/features/tracking/domain/entities/period_summary.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Week or month bars for the selected day's period. Swipe the chart, or
/// use the arrows, to move by a period; tap a bar to select that day.
class HistoryCard extends ConsumerWidget {
  const HistoryCard({required this.habitId, required this.habit, super.key});

  final int habitId;
  final Habit habit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(chartPeriodProvider);
    final today = ref.watch(todayProvider);
    final earliest = ref.watch(earliestDayProvider(habitId));
    final selected = ref.watch(selectedDayProvider(habitId));
    final picker = ref.read(pickedDayProvider.notifier);
    final page = period.periodsBetween(selected, today);
    final pageCount = period.periodsBetween(earliest, today) + 1;
    final range = PeriodRange.of(period, selected);
    final summary = ref
        .watch(periodSummaryProvider((habitId: habitId, range: range)))
        .value;
    final text = context.textTheme;
    final colors = context.colors;

    LogicalDay clamp(LogicalDay day) => day.isAfter(today)
        ? today
        : day.isBefore(earliest)
        ? earliest
        : day;

    void moveToPage(int target) =>
        picker.pick(clamp(period.shift(selected, page - target)));

    void step(int target) {
      unawaited(HapticFeedback.selectionClick());
      moveToPage(target);
    }

    final label = page == 0
        ? (period == ChartPeriod.week ? 'This week' : 'This month')
        : period == ChartPeriod.week
        ? AppFormat.dayRange(range.from, range.to)
        : AppFormat.monthYear(range.from);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(habit.historyTitle, style: text.headlineSmall),
                      Text(
                        'Paced tapering progress',
                        style: text.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 148,
                  child: PillSegmentedControl<ChartPeriod>(
                    selected: period,
                    onChanged: ref.read(chartPeriodProvider.notifier).select,
                    segments: const [
                      PillSegment(value: ChartPeriod.week, label: 'Week'),
                      PillSegment(value: ChartPeriod.month, label: 'Month'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                IconButton(
                  tooltip: period == ChartPeriod.week
                      ? 'Previous week'
                      : 'Previous month',
                  onPressed: page < pageCount - 1 ? () => step(page + 1) : null,
                  icon: const Icon(AppIcons.back, size: 20),
                  color: colors.onSurfaceVariant,
                  disabledColor: colors.outlineVariant,
                ),
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: text.titleSmall,
                  ),
                ),
                IconButton(
                  tooltip: period == ChartPeriod.week
                      ? 'Next week'
                      : 'Next month',
                  onPressed: page > 0 ? () => step(page - 1) : null,
                  icon: const Icon(AppIcons.chevronRight, size: 20),
                  color: colors.onSurfaceVariant,
                  disabledColor: colors.outlineVariant,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
              decoration: BoxDecoration(
                color: colors.surfaceContainer.withValues(alpha: 0.6),
                borderRadius: AppRadius.inner,
              ),
              child: SizedBox(
                height: HistoryChart.height,
                child: BackwardPager(
                  key: ValueKey(period),
                  pageCount: pageCount,
                  page: page,
                  onPageChanged: moveToPage,
                  itemBuilder: (context, index) => _ChartPage(
                    habitId: habitId,
                    range: PeriodRange.of(period, period.shift(today, -index)),
                    selected: selected,
                    canSelect: (day) =>
                        !day.isAfter(today) && !day.isBefore(earliest),
                    onSelect: picker.pick,
                  ),
                ),
              ),
            ),
            if (summary != null) ...[
              const SizedBox(height: AppSpacing.gutterSm),
              _Legend(summary: summary),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChartPage extends ConsumerWidget {
  const _ChartPage({
    required this.habitId,
    required this.range,
    required this.selected,
    required this.canSelect,
    required this.onSelect,
  });

  final int habitId;
  final PeriodRange range;
  final LogicalDay selected;
  final bool Function(LogicalDay day) canSelect;
  final ValueChanged<LogicalDay> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref
        .watch(periodSummaryProvider((habitId: habitId, range: range)))
        .value;
    if (summary == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    return HistoryChart(
      summary: summary,
      selected: selected,
      canSelect: canSelect,
      onSelect: (day) {
        unawaited(HapticFeedback.selectionClick());
        onSelect(day);
      },
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.summary});

  final PeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme.labelMedium;
    final colors = context.colors;
    final average = summary.averagePerDay;
    if (average == null) {
      return Text(
        'Nothing tracked in this period yet.',
        style: text?.copyWith(color: colors.onSurfaceVariant),
      );
    }

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                shape: BoxShape.circle,
              ),
            ),
            Text('Avg ${average.toStringAsFixed(1)}/day', style: text),
          ],
        ),
        Text(
          '${summary.daysOver} ${summary.daysOver == 1 ? 'day' : 'days'} over',
          style: text?.copyWith(
            color: summary.daysOver > 0
                ? context.exhale.danger.foreground
                : colors.onSurfaceVariant,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            Icon(
              AppIcons.checkCircle,
              size: 16,
              color: context.exhale.success.foreground,
            ),
            Text(
              '${summary.daysWithin} '
              '${summary.daysWithin == 1 ? 'day' : 'days'} within limit',
              style: text?.copyWith(color: context.exhale.success.foreground),
            ),
          ],
        ),
      ],
    );
  }
}

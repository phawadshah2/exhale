import 'dart:async';

import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/pill_segmented_control.dart';
import 'package:exhale/features/home/presentation/providers/home_providers.dart';
import 'package:exhale/features/home/presentation/widgets/backward_pager.dart';
import 'package:exhale/features/home/presentation/widgets/history/all_time_chart.dart';
import 'package:exhale/features/home/presentation/widgets/history/history_stats_line.dart';
import 'package:exhale/features/home/presentation/widgets/history/month_ring_calendar.dart';
import 'package:exhale/features/home/presentation/widgets/history/top_triggers.dart';
import 'package:exhale/features/home/presentation/widgets/history/week_line_chart.dart';
import 'package:exhale/features/logs/presentation/logs_query.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:exhale/features/tracking/domain/entities/period_range.dart';
import 'package:exhale/features/tracking/domain/entities/period_stats.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Week line, month rings or the whole plan so far. Swipe the chart, or use
/// the arrows, to move by a period; tap a day to see its logs.
class HistoryCard extends ConsumerWidget {
  const HistoryCard({required this.habitId, super.key});

  final int habitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(historyPeriodProvider(habitId));
    final today = ref.watch(todayProvider);
    final earliest = ref.watch(earliestDayProvider(habitId));
    final shown = ref.watch(historyShownDayProvider(habitId));
    final anchor = ref.read(historyAnchorProvider(habitId).notifier);
    final history = ref.watch(planHistoryProvider(habitId)).value;
    final text = context.textTheme;

    final paged = period.chartPeriod;
    final firstDay = history?.firstDay;
    final range = paged != null
        ? PeriodRange.of(paged, shown)
        : PeriodRange(
            firstDay == null || firstDay.isAfter(today) ? today : firstDay,
            today,
          );
    final stats = ref
        .watch(historyStatsProvider((habitId: habitId, range: range)))
        .value;

    void openDay(LogicalDay day) {
      unawaited(HapticFeedback.selectionClick());
      openLogs(context, LogsQuery(habitId: habitId, from: day, to: day));
    }

    void openPeriod([Trigger? trigger]) => openLogs(
      context,
      LogsQuery(
        habitId: habitId,
        from: range.from,
        to: range.to,
        trigger: trigger,
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('History', style: text.headlineSmall)),
                SizedBox(
                  width: 216,
                  child: PillSegmentedControl<HistoryPeriod>(
                    selected: period,
                    onChanged: ref
                        .read(historyPeriodProvider(habitId).notifier)
                        .select,
                    segments: const [
                      PillSegment(value: HistoryPeriod.week, label: 'Week'),
                      PillSegment(value: HistoryPeriod.month, label: 'Month'),
                      PillSegment(value: HistoryPeriod.all, label: 'All'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (paged != null)
              _PeriodNav(
                period: paged,
                range: range,
                today: today,
                earliest: earliest,
                shown: shown,
                onMove: anchor.pick,
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  _sinceLabel(history, today),
                  textAlign: TextAlign.center,
                  style: text.titleSmall,
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            if (stats != null) ...[
              _Total(stats: stats.stats),
              const SizedBox(height: AppSpacing.gutterSm),
            ],
            if (paged != null)
              _PagedChart(
                habitId: habitId,
                period: paged,
                range: range,
                shown: shown,
                today: today,
                earliest: earliest,
                onMove: anchor.pick,
                onDayTap: openDay,
              )
            else
              _AllChart(habitId: habitId, onTap: openPeriod),
            const SizedBox(height: AppSpacing.gutterSm),
            if (period == HistoryPeriod.month) ...[
              const MonthRingKey(),
              const SizedBox(height: AppSpacing.gutterSm),
            ],
            if (stats != null) ...[
              HistoryStatsLine(stats: stats.stats),
              const SizedBox(height: AppSpacing.gutterSm),
              TopTriggers(
                breakdown: stats.breakdown,
                sinceStart: paged == null,
                onTrigger: openPeriod,
                onAll: openPeriod,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _sinceLabel(PlanHistory? history, LogicalDay today) {
    if (history == null) return 'Since day 1';
    final first = history.firstDay;
    final total = history.current.quitDay.daysSince(first);
    final day = (today.daysSince(first) + 1).clamp(1, total);
    return 'Since ${AppFormat.monthDay(first)} · day $day of $total';
  }
}

class _PeriodNav extends StatelessWidget {
  const _PeriodNav({
    required this.period,
    required this.range,
    required this.today,
    required this.earliest,
    required this.shown,
    required this.onMove,
  });

  final ChartPeriod period;
  final PeriodRange range;
  final LogicalDay today;
  final LogicalDay earliest;
  final LogicalDay shown;
  final ValueChanged<LogicalDay> onMove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final page = period.periodsBetween(shown, today);
    final pageCount = period.periodsBetween(earliest, today) + 1;
    final isWeek = period == ChartPeriod.week;

    void step(int target) {
      unawaited(HapticFeedback.selectionClick());
      onMove(period.shift(shown, page - target));
    }

    final label = page == 0
        ? (isWeek ? 'This week' : 'This month')
        : isWeek
        ? AppFormat.dayRange(range.from, range.to)
        : AppFormat.monthYear(range.from);

    return Row(
      children: [
        IconButton(
          tooltip: isWeek ? 'Previous week' : 'Previous month',
          onPressed: page < pageCount - 1 ? () => step(page + 1) : null,
          icon: const Icon(AppIcons.back, size: 20),
          color: colors.onSurfaceVariant,
          disabledColor: colors.outlineVariant,
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: context.textTheme.titleSmall,
          ),
        ),
        IconButton(
          tooltip: isWeek ? 'Next week' : 'Next month',
          onPressed: page > 0 ? () => step(page - 1) : null,
          icon: const Icon(AppIcons.chevronRight, size: 20),
          color: colors.onSurfaceVariant,
          disabledColor: colors.outlineVariant,
        ),
      ],
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.stats});

  final PeriodStats stats;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final colors = context.colors;
    final under = stats.underBy >= 0;
    final tone = under ? context.exhale.success : context.exhale.danger;
    final showPill = stats.allowedByToday > 0 || stats.logged > 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${stats.logged}',
                      style: text.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: ' / ${stats.allowed} allowed',
                      style: text.titleMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (stats.allowedByToday != stats.allowed)
                Text(
                  '${stats.allowedByToday} allowed by today',
                  style: text.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        if (showPill)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: tone.soft,
              border: Border.all(color: tone.solid.withValues(alpha: 0.45)),
              borderRadius: AppRadius.pill,
            ),
            child: Text(
              under ? '${stats.underBy} under' : '${-stats.underBy} over',
              style: text.labelMedium?.copyWith(
                color: tone.foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _PagedChart extends ConsumerWidget {
  const _PagedChart({
    required this.habitId,
    required this.period,
    required this.range,
    required this.shown,
    required this.today,
    required this.earliest,
    required this.onMove,
    required this.onDayTap,
  });

  final int habitId;
  final ChartPeriod period;
  final PeriodRange range;
  final LogicalDay shown;
  final LogicalDay today;
  final LogicalDay earliest;
  final ValueChanged<LogicalDay> onMove;
  final ValueChanged<LogicalDay> onDayTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = period.periodsBetween(shown, today);
    final pageCount = period.periodsBetween(earliest, today) + 1;
    final height = period == ChartPeriod.week
        ? WeekLineChart.height
        : MonthRingCalendar.heightOf(range);

    LogicalDay clamp(LogicalDay day) => day.isAfter(today)
        ? today
        : day.isBefore(earliest)
        ? earliest
        : day;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer.withValues(alpha: 0.6),
        borderRadius: AppRadius.inner,
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        child: SizedBox(
          height: height,
          child: BackwardPager(
            key: ValueKey(period),
            pageCount: pageCount,
            page: page,
            onPageChanged: (target) =>
                onMove(clamp(period.shift(shown, page - target))),
            itemBuilder: (context, index) => _ChartPage(
              habitId: habitId,
              period: period,
              range: PeriodRange.of(period, period.shift(today, -index)),
              onDayTap: onDayTap,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartPage extends ConsumerWidget {
  const _ChartPage({
    required this.habitId,
    required this.period,
    required this.range,
    required this.onDayTap,
  });

  final int habitId;
  final ChartPeriod period;
  final PeriodRange range;
  final ValueChanged<LogicalDay> onDayTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref
        .watch(periodSummaryProvider((habitId: habitId, range: range)))
        .value;
    if (summary == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    return period == ChartPeriod.week
        ? WeekLineChart(summary: summary, onDayTap: onDayTap)
        : MonthRingCalendar(summary: summary, onDayTap: onDayTap);
  }
}

class _AllChart extends ConsumerWidget {
  const _AllChart({required this.habitId, required this.onTap});

  final int habitId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final series = ref.watch(allTimeSeriesProvider(habitId)).value;
    final quitDay = ref
        .watch(planHistoryProvider(habitId))
        .value
        ?.current
        .quitDay;
    if (series == null || quitDay == null) {
      return const SizedBox(
        height: AllTimeChart.height,
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: context.colors.surfaceContainer.withValues(alpha: 0.6),
              borderRadius: AppRadius.inner,
            ),
            child: AllTimeChart(series: series, quitDay: quitDay),
          ),
        ),
        const SizedBox(height: AppSpacing.gutterSm),
        AllTimeLegend(series: series),
      ],
    );
  }
}

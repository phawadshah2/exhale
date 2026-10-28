import 'dart:async';

import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_motion.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/fill_in.dart';
import 'package:exhale/core/widgets/pill_segmented_control.dart';
import 'package:exhale/core/widgets/smooth_switcher.dart';
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
class HistoryCard extends ConsumerStatefulWidget {
  const HistoryCard({required this.habitId, super.key});

  final int habitId;

  @override
  ConsumerState<HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends ConsumerState<HistoryCard> {
  /// The last stats that loaded, with the period and range they belong to.
  /// Kept while the next period's load, so the card does not collapse and
  /// regrow on every swipe, and keyed by their own range so the swap to new
  /// stats animates once they arrive.
  ({HistoryPeriod period, String key, HistoryStats stats})? _shownStats;

  int get habitId => widget.habitId;

  @override
  Widget build(BuildContext context) {
    final period = ref.watch(historyPeriodProvider(habitId));
    final today = ref.watch(todayProvider);
    final earliest = ref.watch(earliestDayProvider(habitId));
    final shown = ref.watch(historyShownDayProvider(habitId));
    final anchor = ref.read(historyAnchorProvider(habitId).notifier);
    final history = ref.watch(planHistoryProvider(habitId)).value;
    final text = context.textTheme;

    final paged = period.chartPeriod;
    final firstDay = history?.firstDay;
    PeriodRange rangeOf(HistoryPeriod kind) => switch (kind.chartPeriod) {
      final chart? => PeriodRange.of(chart, shown),
      null => PeriodRange(
        firstDay == null || firstDay.isAfter(today) ? today : firstDay,
        today,
      ),
    };
    final range = rangeOf(period);
    // Every period is loaded ahead, so a toggle finds its chart and stats
    // ready and both swap together.
    for (final other in HistoryPeriod.values) {
      final key = (habitId: habitId, range: rangeOf(other));
      ref.watch(historyStatsProvider(key));
      if (other.chartPeriod != null) ref.watch(periodSummaryProvider(key));
    }
    ref.watch(allTimeSeriesProvider(habitId));
    final loaded = ref
        .watch(historyStatsProvider((habitId: habitId, range: range)))
        .value;
    if (loaded != null) {
      _shownStats = (
        period: period,
        key: '$period-${range.from}-${range.to}',
        stats: loaded,
      );
    }
    final shownStats = _shownStats;

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
        // Month length, empty periods and the All view change the height;
        // it eases rather than jumps.
        child: AnimatedSize(
          duration: AppMotion.swap,
          curve: AppMotion.swapCurve,
          alignment: Alignment.topCenter,
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
              SmoothSwitcher(
                child: paged != null
                    ? _PeriodNav(
                        key: ValueKey('nav-${paged.name}'),
                        period: paged,
                        range: range,
                        today: today,
                        earliest: earliest,
                        shown: shown,
                        onMove: anchor.pick,
                      )
                    : Container(
                        key: const ValueKey('since'),
                        // As tall as the arrows row, so toggling does not
                        // change the height.
                        height: 48,
                        alignment: Alignment.center,
                        child: Text(
                          _sinceLabel(history, today),
                          textAlign: TextAlign.center,
                          style: text.titleSmall,
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (shownStats != null) ...[
                SmoothSwitcher(
                  child: KeyedSubtree(
                    key: ValueKey('total-${shownStats.key}'),
                    child: _Total(stats: shownStats.stats.stats),
                  ),
                ),
                const SizedBox(height: AppSpacing.gutterSm),
              ],
              SmoothSwitcher(
                sequential: true,
                resize: true,
                child: KeyedSubtree(
                  key: ValueKey(period),
                  child: paged != null
                      ? _PagedChart(
                          habitId: habitId,
                          period: paged,
                          range: range,
                          shown: shown,
                          today: today,
                          earliest: earliest,
                          onMove: anchor.pick,
                          onDayTap: openDay,
                        )
                      : _AllChart(habitId: habitId, onTap: openPeriod),
                ),
              ),
              const SizedBox(height: AppSpacing.gutterSm),
              SmoothSwitcher(
                sequential: true,
                resize: true,
                child: period == HistoryPeriod.month
                    ? const Padding(
                        key: ValueKey('ring-key'),
                        padding: EdgeInsets.only(bottom: AppSpacing.gutterSm),
                        child: MonthRingKey(),
                      )
                    : const SizedBox(
                        key: ValueKey('no-key'),
                        width: double.infinity,
                      ),
              ),
              if (shownStats != null)
                // A toggle fades the stats and triggers out, then in; a swipe
                // within one period cross-fades them.
                SmoothSwitcher(
                  sequential: true,
                  resize: true,
                  child: KeyedSubtree(
                    key: ValueKey('stats-${shownStats.period}'),
                    child: SmoothSwitcher(
                      resize: true,
                      child: Column(
                        key: ValueKey('stats-${shownStats.key}'),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          HistoryStatsLine(stats: shownStats.stats.stats),
                          const SizedBox(height: AppSpacing.gutterSm),
                          TopTriggers(
                            breakdown: shownStats.stats.breakdown,
                            sinceStart: shownStats.period == HistoryPeriod.all,
                            onTrigger: openPeriod,
                            onAll: openPeriod,
                          ),
                        ],
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
    super.key,
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
              CountUp(
                value: stats.logged,
                builder: (context, logged) => Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$logged',
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
        color: context.colors.surfaceContainerHigh,
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
    if (summary == null) return const SizedBox.shrink();
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
      return const SizedBox(height: AllTimeChart.height);
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
              color: context.colors.surfaceContainerHigh,
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

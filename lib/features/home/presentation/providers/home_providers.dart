import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/tracking/domain/entities/all_time_series.dart';
import 'package:exhale/features/tracking/domain/entities/home_stats.dart';
import 'package:exhale/features/tracking/domain/entities/period_range.dart';
import 'package:exhale/features/tracking/domain/entities/period_stats.dart';
import 'package:exhale/features/tracking/domain/entities/period_summary.dart';
import 'package:exhale/features/tracking/domain/entities/trigger_breakdown.dart';
import 'package:exhale/features/tracking/domain/services/daily_progress_builder.dart';
import 'package:exhale/features/tracking/domain/services/progress_calculator.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

/// What the History card shows: one week, one month, or every day since
/// the plan began.
enum HistoryPeriod {
  week,
  month,
  all;

  /// The paged period behind [week] and [month]; null for [all].
  ChartPeriod? get chartPeriod => switch (this) {
    HistoryPeriod.week => ChartPeriod.week,
    HistoryPeriod.month => ChartPeriod.month,
    HistoryPeriod.all => null,
  };
}

final NotifierProviderFamily<HistoryPeriodController, HistoryPeriod, int>
historyPeriodProvider =
    NotifierProvider.family<HistoryPeriodController, HistoryPeriod, int>(
      HistoryPeriodController.new,
    );

class HistoryPeriodController extends Notifier<HistoryPeriod> {
  HistoryPeriodController(this.habitId);

  final int habitId;

  @override
  HistoryPeriod build() => HistoryPeriod.week;

  // Kept as a method so it can be passed as a tear-off callback.
  // ignore: use_setters_to_change_properties
  void select(HistoryPeriod period) => state = period;
}

/// A habit over a period.
typedef HabitPeriod = ({int habitId, PeriodRange range});

final NotifierProviderFamily<HistoryAnchorController, LogicalDay?, int>
historyAnchorProvider =
    NotifierProvider.family<HistoryAnchorController, LogicalDay?, int>(
      HistoryAnchorController.new,
    );

/// The day whose week or month the History card shows; null means today,
/// which follows midnight.
class HistoryAnchorController extends Notifier<LogicalDay?> {
  HistoryAnchorController(this.habitId);

  final int habitId;

  @override
  LogicalDay? build() => null;

  void pick(LogicalDay day) =>
      state = day == ref.read(todayProvider) ? null : day;

  void showToday() => state = null;
}

/// The day the History card pages from, kept between the habit's
/// [earliestDayProvider] and today.
final ProviderFamily<LogicalDay, int> historyShownDayProvider =
    Provider.family<LogicalDay, int>((ref, habitId) {
      final today = ref.watch(todayProvider);
      final picked = ref.watch(historyAnchorProvider(habitId));
      if (picked == null || !picked.isBefore(today)) return today;
      final earliest = ref.watch(earliestDayProvider(habitId));
      return picked.isBefore(earliest) ? earliest : picked;
    });

final NotifierProviderFamily<RingDayController, LogicalDay?, int>
ringDayProvider = NotifierProvider.family<RingDayController, LogicalDay?, int>(
  RingDayController.new,
);

/// The day picked on the ring card; null means today, which follows
/// midnight.
class RingDayController extends Notifier<LogicalDay?> {
  RingDayController(this.habitId);

  final int habitId;

  @override
  LogicalDay? build() => null;

  void pick(LogicalDay day) =>
      state = day == ref.read(todayProvider) ? null : day;

  void showToday() => state = null;
}

/// The day the ring shows, kept between the habit's [earliestDayProvider]
/// and today.
final ProviderFamily<LogicalDay, int> ringShownDayProvider =
    Provider.family<LogicalDay, int>((ref, habitId) {
      final today = ref.watch(todayProvider);
      final picked = ref.watch(ringDayProvider(habitId));
      if (picked == null || !picked.isBefore(today)) return today;
      final earliest = ref.watch(earliestDayProvider(habitId));
      return picked.isBefore(earliest) ? earliest : picked;
    });

/// The chart for one week or month; null before the habit has a plan.
final FutureProviderFamily<PeriodSummary?, HabitPeriod> periodSummaryProvider =
    FutureProvider.autoDispose.family<PeriodSummary?, HabitPeriod>((
      ref,
      key,
    ) async {
      final today = ref.watch(todayProvider);
      final history = await ref.watch(planHistoryProvider(key.habitId).future);
      if (history == null) return null;
      final logs = await ref.watch(
        logsInRangeProvider((habitId: key.habitId, range: key.range)).future,
      );
      return ProgressCalculator.summarize(
        range: key.range,
        logs: logs,
        boundary: ref.watch(dayBoundaryProvider),
        history: history,
        today: today,
      );
    });

/// Totals and trigger shares for a habit over a period.
typedef HistoryStats = ({PeriodStats stats, TriggerBreakdown breakdown});

/// The History card's totals; null before the habit has a plan. Logs before
/// the plan's first day are left out.
final FutureProviderFamily<HistoryStats?, HabitPeriod> historyStatsProvider =
    FutureProvider.autoDispose.family<HistoryStats?, HabitPeriod>((
      ref,
      key,
    ) async {
      final history = await ref.watch(planHistoryProvider(key.habitId).future);
      if (history == null) return null;
      final logs = await ref.watch(
        logsInRangeProvider((habitId: key.habitId, range: key.range)).future,
      );
      final boundary = ref.watch(dayBoundaryProvider);
      return (
        stats: ProgressCalculator.periodStats(
          range: key.range,
          logs: logs,
          boundary: boundary,
          history: history,
          today: ref.watch(todayProvider),
        ),
        breakdown: ProgressCalculator.triggerBreakdown(
          logs.where(
            (log) => !boundary.dayOf(log.loggedAt).isBefore(history.firstDay),
          ),
        ),
      );
    });

/// Every plan day for the "All" chart; null before the habit has a plan.
final FutureProviderFamily<AllTimeSeries?, int> allTimeSeriesProvider =
    FutureProvider.autoDispose.family<AllTimeSeries?, int>((
      ref,
      habitId,
    ) async {
      final today = ref.watch(todayProvider);
      final history = await ref.watch(planHistoryProvider(habitId).future);
      if (history == null) return null;
      final from = history.firstDay.isAfter(today) ? today : history.firstDay;
      final logs = await ref.watch(
        logsInRangeProvider((habitId: habitId, range: PeriodRange(from, today)))
            .future,
      );
      return ProgressCalculator.allTime(
        logs: logs,
        boundary: ref.watch(dayBoundaryProvider),
        history: history,
        today: today,
      );
    });

/// Streak, baseline change, avoided and saved; null before the habit has a
/// plan.
final FutureProviderFamily<HomeStats?, int> habitStatsProvider = FutureProvider
    .autoDispose
    .family<HomeStats?, int>((ref, habitId) async {
      final today = ref.watch(todayProvider);
      final history = await ref.watch(planHistoryProvider(habitId).future);
      if (history == null) return null;
      final from = history.firstDay.isAfter(today) ? today : history.firstDay;
      final logs = await ref.watch(
        logsInRangeProvider((habitId: habitId, range: PeriodRange(from, today)))
            .future,
      );
      final days = buildDailyProgress(
        logs: logs,
        boundary: ref.watch(dayBoundaryProvider),
        history: history,
        from: history.firstDay,
        to: today,
      );
      return ProgressCalculator.homeStats(
        days: days,
        history: history,
        today: today,
        unitPriceCents: ref.watch(habitProvider(habitId))?.unitPriceCents,
      );
    });

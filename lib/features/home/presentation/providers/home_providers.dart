import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/tracking/domain/entities/habit_log.dart';
import 'package:exhale/features/tracking/domain/entities/home_stats.dart';
import 'package:exhale/features/tracking/domain/entities/period_range.dart';
import 'package:exhale/features/tracking/domain/entities/period_summary.dart';
import 'package:exhale/features/tracking/domain/services/daily_progress_builder.dart';
import 'package:exhale/features/tracking/domain/services/progress_calculator.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

final chartPeriodProvider =
    NotifierProvider<ChartPeriodController, ChartPeriod>(
      ChartPeriodController.new,
    );

class ChartPeriodController extends Notifier<ChartPeriod> {
  @override
  ChartPeriod build() => ChartPeriod.week;

  // Kept as a method so it can be passed as a tear-off callback.
  // ignore: use_setters_to_change_properties
  void select(ChartPeriod period) => state = period;
}

/// A habit, or every active habit when null, over a period.
typedef LogsInRange = ({int? habitId, PeriodRange range});

/// A habit over a period.
typedef HabitPeriod = ({int habitId, PeriodRange range});

/// Logs on the days in the range, oldest first.
final StreamProviderFamily<List<HabitLog>, LogsInRange> logsInRangeProvider =
    StreamProvider.autoDispose.family<List<HabitLog>, LogsInRange>((ref, key) {
      final boundary = ref.watch(dayBoundaryProvider);
      return ref
          .watch(habitLogRepositoryProvider)
          .watchLogs(
            habitId: key.habitId,
            from: boundary.startOf(key.range.from),
            to: boundary.endOf(key.range.to),
          );
    });

/// How many days before the plan's first day Home can show and back-fill.
const int backfillDays = 30;

/// The earliest day Home can show for a habit: [backfillDays] before its
/// first plan day.
final ProviderFamily<LogicalDay, int> earliestDayProvider =
    Provider.family<LogicalDay, int>((ref, habitId) {
      final today = ref.watch(todayProvider);
      final firstDay = ref.watch(planHistoryProvider(habitId)).value?.firstDay;
      if (firstDay == null) return today;
      final earliest = firstDay.addDays(-backfillDays);
      return earliest.isAfter(today) ? today : earliest;
    });

final pickedDayProvider = NotifierProvider<PickedDayController, LogicalDay?>(
  PickedDayController.new,
);

/// The day picked on Home; null means today, which follows midnight.
class PickedDayController extends Notifier<LogicalDay?> {
  @override
  LogicalDay? build() => null;

  void pick(LogicalDay day) =>
      state = day == ref.read(todayProvider) ? null : day;

  void showToday() => state = null;
}

/// The day the ring shows and the chart highlights, kept between the
/// habit's [earliestDayProvider] and today.
final ProviderFamily<LogicalDay, int> selectedDayProvider =
    Provider.family<LogicalDay, int>((ref, habitId) {
      final today = ref.watch(todayProvider);
      final picked = ref.watch(pickedDayProvider);
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

import 'package:exhale/core/domain/time/logical_day.dart';
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

/// The current habit's logs on the days in [PeriodRange], oldest first.
final StreamProviderFamily<List<HabitLog>, PeriodRange> logsInRangeProvider =
    StreamProvider.autoDispose.family<List<HabitLog>, PeriodRange>((
      ref,
      range,
    ) {
      final boundary = ref.watch(dayBoundaryProvider);
      return ref
          .watch(habitLogRepositoryProvider)
          .watchLogs(
            habitKind: ref.watch(habitProvider).kind,
            from: boundary.startOf(range.from),
            to: boundary.endOf(range.to),
          );
    });

/// How many days before the plan's first day Home can show and back-fill.
const int backfillDays = 30;

/// The earliest day Home can show: [backfillDays] before the first plan day.
final Provider<LogicalDay> earliestDayProvider = Provider<LogicalDay>((ref) {
  final today = ref.watch(todayProvider);
  final firstDay = ref.watch(planHistoryProvider).value?.firstDay;
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

/// The day the ring shows and the chart highlights, kept between
/// [earliestDayProvider] and today.
final Provider<LogicalDay> selectedDayProvider = Provider<LogicalDay>((ref) {
  final today = ref.watch(todayProvider);
  final picked = ref.watch(pickedDayProvider);
  if (picked == null || !picked.isBefore(today)) return today;
  final earliest = ref.watch(earliestDayProvider);
  return picked.isBefore(earliest) ? earliest : picked;
});

/// The chart for one week or month; null before a plan exists.
final FutureProviderFamily<PeriodSummary?, PeriodRange> periodSummaryProvider =
    FutureProvider.autoDispose.family<PeriodSummary?, PeriodRange>((
      ref,
      range,
    ) async {
      final today = ref.watch(todayProvider);
      final history = await ref.watch(planHistoryProvider.future);
      if (history == null) return null;
      final logs = await ref.watch(logsInRangeProvider(range).future);
      return ProgressCalculator.summarize(
        range: range,
        logs: logs,
        boundary: ref.watch(dayBoundaryProvider),
        history: history,
        today: today,
      );
    });

/// Streak, baseline change, avoided and saved; null before a plan exists.
final FutureProvider<HomeStats?> homeStatsProvider =
    FutureProvider.autoDispose<HomeStats?>((ref) async {
      final today = ref.watch(todayProvider);
      final history = await ref.watch(planHistoryProvider.future);
      if (history == null) return null;
      final from = history.firstDay.isAfter(today) ? today : history.firstDay;
      final logs = await ref.watch(
        logsInRangeProvider(PeriodRange(from, today)).future,
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
        unitPriceCents: ref.watch(currentSettingsProvider).unitPriceCents,
      );
    });

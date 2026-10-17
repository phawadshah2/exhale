import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/tracking/domain/entities/home_stats.dart';
import 'package:exhale/features/tracking/domain/entities/period_range.dart';
import 'package:exhale/features/tracking/domain/entities/period_summary.dart';
import 'package:exhale/features/tracking/domain/entities/smoke_log.dart';
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

/// Logs on the logical days in [PeriodRange], oldest first.
final StreamProviderFamily<List<SmokeLog>, PeriodRange> logsInRangeProvider =
    StreamProvider.autoDispose.family<List<SmokeLog>, PeriodRange>((
      ref,
      range,
    ) {
      final boundary = ref.watch(dayBoundaryProvider);
      return ref
          .watch(smokeLogRepositoryProvider)
          .watchLogs(
            from: boundary.startOf(range.from),
            to: boundary.endOf(range.to),
          );
    });

/// The week or month shown in the history chart; null before a plan exists.
final FutureProvider<PeriodSummary?> periodSummaryProvider =
    FutureProvider.autoDispose<PeriodSummary?>((ref) async {
      final today = ref.watch(todayProvider);
      final range = PeriodRange.of(ref.watch(chartPeriodProvider), today);
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
        cigarettePriceCents: ref
            .watch(currentSettingsProvider)
            .cigarettePriceCents,
      );
    });

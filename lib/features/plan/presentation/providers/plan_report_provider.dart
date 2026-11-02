import 'package:exhale/core/widgets/load_failure.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/plan/domain/services/plan_report.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/tracking/domain/entities/period_range.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

/// A habit's plans, logs and prices as one report; data of null before the
/// habit has a plan.
final ProviderFamily<AsyncValue<PlanReport?>, int> planReportProvider = Provider
    .autoDispose
    .family<AsyncValue<PlanReport?>, int>((ref, habitId) {
      final history = ref.watch(planHistoryProvider(habitId));
      final prices = ref.watch(priceHistoryProvider(habitId));
      if (history.failedToLoad) {
        return AsyncError(history.error!, history.stackTrace!);
      }
      if (prices.failedToLoad) {
        return AsyncError(prices.error!, prices.stackTrace!);
      }
      if (!history.hasValue || !prices.hasValue) return const AsyncLoading();
      final plans = history.value;
      if (plans == null) return const AsyncData(null);

      final today = ref.watch(todayProvider);
      final from = plans.firstDay.isAfter(today) ? today : plans.firstDay;
      final logs = ref.watch(
        logsInRangeProvider((
          habitId: habitId,
          range: PeriodRange(from, today),
        )),
      );
      if (logs.failedToLoad) return AsyncError(logs.error!, logs.stackTrace!);
      final logged = logs.value;
      if (logged == null) return const AsyncLoading();

      return AsyncData(
        PlanReport.build(
          logs: logged,
          boundary: ref.watch(dayBoundaryProvider),
          history: plans,
          prices: prices.value,
          today: today,
        ),
      );
    });

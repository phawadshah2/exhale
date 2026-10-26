import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/providers/clock_providers.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/tracking/domain/entities/daily_progress.dart';
import 'package:exhale/features/tracking/domain/entities/habit_log.dart';
import 'package:exhale/features/tracking/domain/repositories/habit_log_repository.dart';
import 'package:exhale/features/tracking/domain/usecases/add_habit_log.dart';
import 'package:exhale/features/tracking/domain/usecases/delete_habit_log.dart';
import 'package:exhale/features/tracking/domain/usecases/update_habit_log.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

final habitLogRepositoryProvider = Provider<HabitLogRepository>(
  (ref) => sl<HabitLogRepository>(),
);

final addHabitLogProvider = Provider<AddHabitLog>((ref) => sl<AddHabitLog>());

final updateHabitLogProvider = Provider<UpdateHabitLog>(
  (ref) => sl<UpdateHabitLog>(),
);

final deleteHabitLogProvider = Provider<DeleteHabitLog>(
  (ref) => sl<DeleteHabitLog>(),
);

/// The logical day it is now, under the user's reset hour.
final todayProvider = Provider<LogicalDay>((ref) {
  final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider).now();
  return ref.watch(dayBoundaryProvider).dayOf(now);
});

/// A habit on one logical day.
typedef HabitDay = ({int habitId, LogicalDay day});

/// The habit's logs on the day, oldest first.
final StreamProviderFamily<List<HabitLog>, HabitDay> logsForDayProvider =
    StreamProvider.autoDispose.family<List<HabitLog>, HabitDay>((ref, key) {
      final boundary = ref.watch(dayBoundaryProvider);
      return ref
          .watch(habitLogRepositoryProvider)
          .watchLogs(
            habitId: key.habitId,
            from: boundary.startOf(key.day),
            to: boundary.endOf(key.day),
          );
    });

/// The habit's most recent log.
final StreamProviderFamily<HabitLog?, int> latestLogProvider =
    StreamProvider.family<HabitLog?, int>(
      (ref, habitId) =>
          ref.watch(habitLogRepositoryProvider).watchLatest(habitId: habitId),
    );

/// The day's count against that day's limit; null before the habit has a
/// plan. Days before the plan use the first plan's limit; callers decide
/// whether to show it.
final FutureProviderFamily<DailyProgress?, HabitDay> dayProgressProvider =
    FutureProvider.autoDispose.family<DailyProgress?, HabitDay>((
      ref,
      key,
    ) async {
      final history = await ref.watch(planHistoryProvider(key.habitId).future);
      if (history == null) return null;
      final logs = await ref.watch(logsForDayProvider(key).future);
      return DailyProgress(
        day: key.day,
        count: logs.length,
        limit: history.limitOn(key.day),
      );
    });

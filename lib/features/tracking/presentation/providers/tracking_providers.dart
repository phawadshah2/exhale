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

/// The current habit's logs on [LogicalDay], oldest first.
final StreamProviderFamily<List<HabitLog>, LogicalDay> logsForDayProvider =
    StreamProvider.autoDispose.family<List<HabitLog>, LogicalDay>((ref, day) {
      final boundary = ref.watch(dayBoundaryProvider);
      return ref
          .watch(habitLogRepositoryProvider)
          .watchLogs(
            habitKind: ref.watch(habitProvider).kind,
            from: boundary.startOf(day),
            to: boundary.endOf(day),
          );
    });

/// The current habit's most recent log.
final latestLogProvider = StreamProvider<HabitLog?>(
  (ref) => ref
      .watch(habitLogRepositoryProvider)
      .watchLatest(habitKind: ref.watch(habitProvider).kind),
);

/// Today's count against today's limit; null before a plan exists.
final todayProgressProvider = FutureProvider<DailyProgress?>((ref) async {
  final day = ref.watch(todayProvider);
  final history = await ref.watch(planHistoryProvider.future);
  if (history == null) return null;
  final logs = await ref.watch(logsForDayProvider(day).future);
  return DailyProgress(
    day: day,
    count: logs.length,
    limit: history.limitOn(day),
  );
});

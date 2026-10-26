import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/features/tracking/domain/entities/habit_log.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';

/// A null `habitId` in a query means every active habit.
abstract interface class HabitLogRepository {
  Future<Result<HabitLog>> addLog({
    required int habitId,
    required DateTime loggedAt,
    Trigger? trigger,
    String? note,
  });

  Future<Result<void>> updateLog(HabitLog log);

  Future<Result<void>> deleteLog(int id);

  /// Logs with `from <= loggedAt < to`, oldest first.
  Stream<List<HabitLog>> watchLogs({
    required DateTime from,
    required DateTime to,
    int? habitId,
  });

  Stream<HabitLog?> watchLatest({int? habitId});

  /// The newest [limit] logs of every active habit, newest first.
  Stream<List<HabitLog>> watchRecent({required int limit});
}

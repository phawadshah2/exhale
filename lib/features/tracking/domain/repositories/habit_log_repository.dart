import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/tracking/domain/entities/habit_log.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';

abstract interface class HabitLogRepository {
  Future<Result<HabitLog>> addLog({
    required DateTime loggedAt,
    required HabitKind habitKind,
    Trigger? trigger,
    String? note,
  });

  Future<Result<void>> updateLog(HabitLog log);

  Future<Result<void>> deleteLog(int id);

  /// [habitKind]'s logs with `from <= loggedAt < to`, oldest first.
  Stream<List<HabitLog>> watchLogs({
    required HabitKind habitKind,
    required DateTime from,
    required DateTime to,
  });

  /// [habitKind]'s most recent log.
  Stream<HabitLog?> watchLatest({required HabitKind habitKind});
}

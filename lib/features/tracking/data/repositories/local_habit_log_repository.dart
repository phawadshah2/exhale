import 'package:exhale/core/data/storage_guard.dart';
import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/tracking/data/datasources/habit_log_local_data_source.dart';
import 'package:exhale/features/tracking/data/models/habit_log_model.dart';
import 'package:exhale/features/tracking/domain/entities/habit_log.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:exhale/features/tracking/domain/repositories/habit_log_repository.dart';

class LocalHabitLogRepository implements HabitLogRepository {
  const LocalHabitLogRepository(this._localDataSource);
  final HabitLogLocalDataSource _localDataSource;

  static const _source = 'LocalHabitLogRepository';

  @override
  Future<Result<HabitLog>> addLog({
    required DateTime loggedAt,
    required HabitKind habitKind,
    Trigger? trigger,
    String? note,
  }) => guardStorage(_source, () async {
    final row = await _localDataSource.insertLog(
      habitLogCompanion(
        loggedAt: loggedAt,
        habitKind: habitKind,
        trigger: trigger,
        note: note,
      ),
    );
    return row.toEntity();
  });

  @override
  Future<Result<void>> updateLog(HabitLog log) async {
    final result = await guardStorage(
      _source,
      () => _localDataSource.updateLog(
        log.id,
        habitLogCompanion(
          loggedAt: log.loggedAt,
          habitKind: log.habitKind,
          trigger: log.trigger,
          note: log.note,
        ),
      ),
    );
    return _requireRow(result);
  }

  @override
  Future<Result<void>> deleteLog(int id) async => _requireRow(
    await guardStorage(_source, () => _localDataSource.deleteLog(id)),
  );

  @override
  Stream<List<HabitLog>> watchLogs({
    required HabitKind habitKind,
    required DateTime from,
    required DateTime to,
  }) => _localDataSource
      .watchLogs(habitKind: habitKind.name, from: from, to: to)
      .map((rows) => rows.map((row) => row.toEntity()).toList());

  @override
  Stream<HabitLog?> watchLatest({required HabitKind habitKind}) =>
      _localDataSource
          .watchLatest(habitKind: habitKind.name)
          .map((row) => row?.toEntity());

  Result<void> _requireRow(Result<int> result) => switch (result) {
    Success(value: 0) => const FailureResult<void>(NotFoundFailure()),
    Success() => const Success<void>(null),
    FailureResult(:final failure) => FailureResult<void>(failure),
  };
}

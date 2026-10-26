import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/core/data/storage_guard.dart';
import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
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
    required int habitId,
    required DateTime loggedAt,
    Trigger? trigger,
    String? note,
  }) => guardStorage(_source, () async {
    final row = await _localDataSource.insertLog(
      habitLogCompanion(
        habitId: habitId,
        loggedAt: loggedAt,
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
          habitId: log.habitId,
          loggedAt: log.loggedAt,
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
    required DateTime from,
    required DateTime to,
    int? habitId,
  }) => _localDataSource
      .watchLogs(habitId: habitId, from: from, to: to)
      .map(_toEntities);

  @override
  Stream<HabitLog?> watchLatest({int? habitId}) => _localDataSource
      .watchLatest(habitId: habitId)
      .map((row) => row?.toEntity());

  @override
  Stream<List<HabitLog>> watchRecent({required int limit}) =>
      _localDataSource.watchRecent(limit: limit).map(_toEntities);

  List<HabitLog> _toEntities(List<HabitLogRow> rows) =>
      rows.map((row) => row.toEntity()).toList();

  Result<void> _requireRow(Result<int> result) => switch (result) {
    Success(value: 0) => const FailureResult<void>(NotFoundFailure()),
    Success() => const Success<void>(null),
    FailureResult(:final failure) => FailureResult<void>(failure),
  };
}

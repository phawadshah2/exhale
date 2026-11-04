import 'package:exhale/core/data/storage_guard.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/plan/data/datasources/stage_check_local_data_source.dart';
import 'package:exhale/features/plan/data/models/stage_check_model.dart';
import 'package:exhale/features/plan/domain/entities/plan_hold.dart';
import 'package:exhale/features/plan/domain/entities/stage_check.dart';
import 'package:exhale/features/plan/domain/repositories/stage_check_repository.dart';

class LocalStageCheckRepository implements StageCheckRepository {
  const LocalStageCheckRepository(this._localDataSource);
  final StageCheckLocalDataSource _localDataSource;

  static const _source = 'LocalStageCheckRepository';

  @override
  Stream<List<StageCheck>> watchChecks(int habitId) => _localDataSource
      .watchChecks(habitId)
      .map((rows) => [for (final row in rows) row.toEntity()]);

  @override
  Future<Result<List<StageCheck>>> getChecks(int habitId) => guardStorage(
    _source,
    () async => [
      for (final row in await _localDataSource.getChecks(habitId))
        row.toEntity(),
    ],
  );

  @override
  Future<Result<void>> record(
    int habitId,
    StageCheck check, {
    PlanHold? hold,
    LogicalDay? closesHoldWindow,
  }) => guardStorage(
    _source,
    () => _localDataSource.record(
      habitId,
      check,
      hold: hold,
      closesHoldWindow: closesHoldWindow,
    ),
  );

  @override
  Future<Result<void>> answer(
    int habitId,
    LogicalDay planStartDay,
    LogicalDay windowEndDay,
    DateTime at,
  ) => guardStorage(
    _source,
    () => _localDataSource.answer(habitId, planStartDay, windowEndDay, at),
  );

  @override
  Future<Result<void>> keepOriginalDate(
    int habitId,
    LogicalDay planStartDay,
    LogicalDay windowEndDay,
    LogicalDay holdStart,
    DateTime at,
  ) => guardStorage(
    _source,
    () => _localDataSource.keepOriginalDate(
      habitId,
      planStartDay,
      windowEndDay,
      holdStart,
      at,
    ),
  );
}

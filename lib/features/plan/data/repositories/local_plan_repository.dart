import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/core/data/storage_guard.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/features/plan/data/datasources/plan_local_data_source.dart';
import 'package:exhale/features/plan/data/models/plan_model.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/plan/domain/repositories/plan_repository.dart';

class LocalPlanRepository implements PlanRepository {
  const LocalPlanRepository(this._localDataSource);
  final PlanLocalDataSource _localDataSource;

  static const _source = 'LocalPlanRepository';

  @override
  Stream<PlanHistory?> watchHistory(int habitId) =>
      _localDataSource.watchPlans(habitId).map(_toHistory);

  @override
  Future<Result<PlanHistory?>> getHistory(int habitId) => guardStorage(
    _source,
    () async => _toHistory(await _localDataSource.getPlans(habitId)),
  );

  @override
  Future<Result<void>> savePlan(int habitId, ReductionPlan plan) =>
      guardStorage(
        _source,
        () => _localDataSource.replaceFrom(plan.toCompanion(habitId)),
      );

  PlanHistory? _toHistory(List<PlanRow> rows) =>
      rows.isEmpty ? null : PlanHistory(rows.map((row) => row.toEntity()));
}

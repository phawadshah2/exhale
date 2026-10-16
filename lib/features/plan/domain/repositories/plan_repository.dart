import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';

abstract interface class PlanRepository {
  /// Emits null until the first plan is saved.
  Stream<PlanHistory?> watchHistory();

  Future<Result<PlanHistory?>> getHistory();

  /// Makes [plan] current from its start day. Plans starting on or after
  /// that day are replaced; earlier ones are kept as history.
  Future<Result<void>> savePlan(ReductionPlan plan);
}

import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';

abstract interface class PlanRepository {
  /// Emits null until [habitId]'s first plan is saved.
  Stream<PlanHistory?> watchHistory(int habitId);

  Future<Result<PlanHistory?>> getHistory(int habitId);

  /// Makes [plan] current for [habitId] from its start day. That habit's
  /// plans starting on or after that day are replaced; earlier ones are
  /// kept as history.
  Future<Result<void>> savePlan(int habitId, ReductionPlan plan);
}

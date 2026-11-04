import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/plan/domain/entities/plan_hold.dart';
import 'package:exhale/features/plan/domain/entities/stage_check.dart';

abstract interface class StageCheckRepository {
  /// Newest first.
  Stream<List<StageCheck>> watchChecks(int habitId);

  Future<Result<List<StageCheck>>> getChecks(int habitId);

  /// Writes [check] with its [hold], together. A check for a window already
  /// recorded writes nothing and succeeds. [closesHoldWindow] answers the
  /// still waiting hold card of that earlier window in the same write.
  Future<Result<void>> record(
    int habitId,
    StageCheck check, {
    PlanHold? hold,
    LogicalDay? closesHoldWindow,
  });

  /// Marks the check of a window answered at [at].
  Future<Result<void>> answer(
    int habitId,
    LogicalDay planStartDay,
    LogicalDay windowEndDay,
    DateTime at,
  );

  /// Deletes the hold that started on [holdStart] and answers the check,
  /// together.
  Future<Result<void>> keepOriginalDate(
    int habitId,
    LogicalDay planStartDay,
    LogicalDay windowEndDay,
    LogicalDay holdStart,
    DateTime at,
  );
}

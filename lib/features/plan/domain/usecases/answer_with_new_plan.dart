import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/domain/transaction/transaction_runner.dart';
import 'package:exhale/core/domain/usecase/usecase.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/plan/domain/usecases/answer_stage_check.dart';
import 'package:exhale/features/plan/domain/usecases/save_plan.dart';

typedef AnswerWithNewPlanInput = ({
  int habitId,
  PlanDraft draft,
  LogicalDay planStartDay,
  LogicalDay windowEndDay,
});

/// Answers a review or reassess card by starting a new plan. The answer and
/// the plan are saved together or not at all. The answer goes first: a plan
/// starting on the old plan's own start day takes the old plan's checks
/// with it.
class AnswerWithNewPlan
    implements UseCase<ReductionPlan, AnswerWithNewPlanInput> {
  const AnswerWithNewPlan(this._answer, this._savePlan, this._transactions);
  final AnswerStageCheck _answer;
  final SavePlan _savePlan;
  final TransactionRunner _transactions;

  @override
  Future<Result<ReductionPlan>> call(AnswerWithNewPlanInput input) async {
    try {
      return await _transactions.run(() async {
        final answered = await _answer((
          habitId: input.habitId,
          planStartDay: input.planStartDay,
          windowEndDay: input.windowEndDay,
        ));
        if (answered case FailureResult(:final failure)) throw _Abort(failure);
        final saved = await _savePlan((
          habitId: input.habitId,
          draft: input.draft,
        ));
        if (saved case FailureResult(:final failure)) throw _Abort(failure);
        return saved;
      });
    } on _Abort catch (abort) {
      return FailureResult<ReductionPlan>(abort.failure);
    }
  }
}

/// Rolls the transaction back with the failure that stopped it.
class _Abort implements Exception {
  const _Abort(this.failure);
  final Failure failure;
}

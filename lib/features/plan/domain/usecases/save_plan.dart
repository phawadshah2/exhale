import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/usecase/usecase.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/plan/domain/repositories/plan_repository.dart';
import 'package:exhale/features/plan/domain/validation/plan_validation.dart';

typedef SavePlanInput = ({int habitId, PlanDraft draft});

class SavePlan implements UseCase<ReductionPlan, SavePlanInput> {
  const SavePlan(this._repository);
  final PlanRepository _repository;

  @override
  Future<Result<ReductionPlan>> call(SavePlanInput input) async {
    final draft = input.draft;
    final error = PlanValidation.validate(draft);
    if (error != null) {
      return FailureResult<ReductionPlan>(ValidationFailure(error));
    }

    final plan = ReductionPlan(
      startDay: draft.startDay,
      startLimit: draft.startLimit,
      quitDay: draft.quitDay,
    );
    return switch (await _repository.savePlan(input.habitId, plan)) {
      Success() => Success<ReductionPlan>(plan),
      FailureResult(:final failure) => FailureResult<ReductionPlan>(failure),
    };
  }
}

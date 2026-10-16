import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/usecase/usecase.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/plan/domain/repositories/plan_repository.dart';
import 'package:exhale/features/plan/domain/validation/plan_validation.dart';

class SavePlan implements UseCase<ReductionPlan, PlanDraft> {
  const SavePlan(this._repository);
  final PlanRepository _repository;

  @override
  Future<Result<ReductionPlan>> call(PlanDraft draft) async {
    final error = PlanValidation.validate(draft);
    if (error != null) {
      return FailureResult<ReductionPlan>(ValidationFailure(error));
    }

    final plan = ReductionPlan(
      startDay: draft.startDay,
      startLimit: draft.startLimit,
      stepDays: draft.stepDays,
      targetLimit: draft.targetLimit,
    );
    return switch (await _repository.savePlan(plan)) {
      Success() => Success<ReductionPlan>(plan),
      FailureResult(:final failure) => FailureResult<ReductionPlan>(failure),
    };
  }
}

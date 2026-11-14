import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/usecase/usecase.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/plan/domain/repositories/plan_repository.dart';
import 'package:exhale/features/plan/domain/validation/plan_validation.dart';
import 'package:exhale/features/tracking/domain/repositories/habit_log_repository.dart';

typedef RestartUnstartedPlanInput = ({int habitId, PlanDraft draft});

/// Replaces every plan of a habit that has never been logged with the draft.
/// A habit with logs keeps its plans, so tracked days keep their limits.
class RestartUnstartedPlan implements UseCase<void, RestartUnstartedPlanInput> {
  const RestartUnstartedPlan(this._plans, this._logs);
  final PlanRepository _plans;
  final HabitLogRepository _logs;

  @override
  Future<Result<void>> call(RestartUnstartedPlanInput input) async {
    final draft = input.draft;
    final error = PlanValidation.validate(draft);
    if (error != null) return FailureResult<void>(ValidationFailure(error));

    return switch (await _logs.hasLogs(input.habitId)) {
      FailureResult(:final failure) => FailureResult<void>(failure),
      Success(value: true) => const Success<void>(null),
      Success() => await _plans.replaceAll(
        input.habitId,
        ReductionPlan(
          startDay: draft.startDay,
          startLimit: draft.startLimit,
          quitDay: draft.quitDay,
        ),
      ),
    };
  }
}

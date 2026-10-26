import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/transaction/transaction_runner.dart';
import 'package:exhale/core/domain/usecase/usecase.dart';
import 'package:exhale/features/habit/domain/entities/habit_draft.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:exhale/features/habit/domain/usecases/add_habit.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/plan/domain/usecases/save_plan.dart';

typedef StartTrackingInput = ({HabitDraft habit, PlanDraft plan});

/// Adds a habit together with its first plan; neither is kept without the
/// other.
class StartTracking implements UseCase<TrackedHabit, StartTrackingInput> {
  const StartTracking(this._addHabit, this._savePlan, this._transactions);
  final AddHabit _addHabit;
  final SavePlan _savePlan;
  final TransactionRunner _transactions;

  @override
  Future<Result<TrackedHabit>> call(StartTrackingInput input) async {
    try {
      return await _transactions.run(() async {
        final habit = switch (await _addHabit(input.habit)) {
          Success(:final value) => value,
          FailureResult(:final failure) => throw _Abort(failure),
        };
        final saved = await _savePlan((habitId: habit.id, draft: input.plan));
        if (saved case FailureResult(:final failure)) throw _Abort(failure);
        return Success<TrackedHabit>(habit);
      });
    } on _Abort catch (abort) {
      return FailureResult<TrackedHabit>(abort.failure);
    }
  }
}

/// Rolls the transaction back with the failure that stopped it.
class _Abort implements Exception {
  const _Abort(this.failure);
  final Failure failure;
}

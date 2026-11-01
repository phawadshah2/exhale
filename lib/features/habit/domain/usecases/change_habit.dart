import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/transaction/transaction_runner.dart';
import 'package:exhale/core/domain/usecase/usecase.dart';
import 'package:exhale/features/habit/domain/entities/habit_draft.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:exhale/features/habit/domain/repositories/habit_repository.dart';
import 'package:exhale/features/habit/domain/usecases/archive_habit.dart';
import 'package:exhale/features/habit/domain/usecases/start_tracking.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';

typedef ChangeHabitInput = ({
  int replacedHabitId,
  HabitDraft habit,
  PlanDraft plan,
});

/// Replaces an active habit with a new one and its first plan. The old habit
/// stops being tracked only if the new one saves; its plans and logs are kept.
class ChangeHabit implements UseCase<TrackedHabit, ChangeHabitInput> {
  const ChangeHabit(
    this._habits,
    this._archiveHabit,
    this._startTracking,
    this._transactions,
  );
  final HabitRepository _habits;
  final ArchiveHabit _archiveHabit;
  final StartTracking _startTracking;
  final TransactionRunner _transactions;

  @override
  Future<Result<TrackedHabit>> call(ChangeHabitInput input) async {
    try {
      return await _transactions.run(() async {
        final active = switch (await _habits.getActive()) {
          Success(:final value) => value,
          FailureResult(:final failure) => throw _Abort(failure),
        };
        if (!active.any((habit) => habit.id == input.replacedHabitId)) {
          throw const _Abort(NotFoundFailure());
        }
        final archived = await _archiveHabit(input.replacedHabitId);
        if (archived case FailureResult(:final failure)) throw _Abort(failure);
        // StartTracking rolls back only its own part, so its failure has to
        // be thrown again to restore the old habit.
        final started = await _startTracking((
          habit: input.habit,
          plan: input.plan,
        ));
        if (started case FailureResult(:final failure)) throw _Abort(failure);
        return started;
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

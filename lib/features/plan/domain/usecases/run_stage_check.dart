import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/day_boundary.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/domain/transaction/transaction_runner.dart';
import 'package:exhale/core/domain/usecase/usecase.dart';
import 'package:exhale/features/plan/domain/entities/stage_check.dart';
import 'package:exhale/features/plan/domain/repositories/plan_repository.dart';
import 'package:exhale/features/plan/domain/repositories/stage_check_repository.dart';
import 'package:exhale/features/plan/domain/services/stage_checks.dart';
import 'package:exhale/features/tracking/domain/repositories/habit_log_repository.dart';

typedef RunStageCheckInput = ({
  int habitId,
  LogicalDay today,
  DayBoundary boundary,
});

/// Runs the stage check due today, if there is one, and stores its result.
/// Reading and writing share one transaction, so two runs at once store one
/// check.
class RunStageCheck implements UseCase<void, RunStageCheckInput> {
  const RunStageCheck(
    this._plans,
    this._checks,
    this._logs,
    this._transactions,
  );
  final PlanRepository _plans;
  final StageCheckRepository _checks;
  final HabitLogRepository _logs;
  final TransactionRunner _transactions;

  /// A window and the 14 days behind a near-start check both fit in this
  /// many days before today; later stages are skipped.
  static const _logDays = 20;

  @override
  Future<Result<void>> call(RunStageCheckInput input) async {
    try {
      return await _transactions.run(() => _run(input));
    } on _Abort catch (abort) {
      return FailureResult<void>(abort.failure);
    }
  }

  Future<Result<void>> _run(RunStageCheckInput input) async {
    final history = switch (await _plans.getHistory(input.habitId)) {
      Success(:final value) => value,
      FailureResult(:final failure) => throw _Abort(failure),
    };
    if (history == null) return const Success<void>(null);

    final checks = switch (await _checks.getChecks(input.habitId)) {
      Success(:final value) => value,
      FailureResult(:final failure) => throw _Abort(failure),
    };
    final logs = switch (await _logs.getLogs(
      habitId: input.habitId,
      from: input.boundary.startOf(input.today.addDays(-_logDays)),
      to: input.boundary.endOf(input.today),
    )) {
      Success(:final value) => value,
      FailureResult(:final failure) => throw _Abort(failure),
    };

    final result = StageChecks.evaluate(
      history: history,
      logs: logs,
      boundary: input.boundary,
      checks: checks,
      today: input.today,
    );
    if (result == null) return const Success<void>(null);

    final planStart = history.current.startDay;
    final waitingHold = result.closesWaitingHold
        ? checks.firstWhere(
            (c) =>
                c.planStartDay == planStart &&
                c.outcome == StageOutcome.hold &&
                c.answeredAt == null,
          )
        : null;

    final recorded = await _checks.record(
      input.habitId,
      StageCheck(
        planStartDay: planStart,
        windowEndDay: result.windowEndDay,
        checkDay: input.today,
        outcome: result.outcome,
      ),
      hold: result.hold,
      closesHoldWindow: waitingHold?.windowEndDay,
    );
    if (recorded case FailureResult(:final failure)) throw _Abort(failure);
    return const Success<void>(null);
  }
}

/// Rolls the transaction back with the failure that stopped it.
class _Abort implements Exception {
  const _Abort(this.failure);
  final Failure failure;
}

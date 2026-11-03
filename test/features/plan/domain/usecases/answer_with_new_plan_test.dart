import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/core/data/local/database/drift_transaction_runner.dart';
import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/plan/data/datasources/plan_local_data_source.dart';
import 'package:exhale/features/plan/data/datasources/stage_check_local_data_source.dart';
import 'package:exhale/features/plan/data/repositories/local_plan_repository.dart';
import 'package:exhale/features/plan/data/repositories/local_stage_check_repository.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/plan/domain/entities/stage_check.dart';
import 'package:exhale/features/plan/domain/usecases/answer_stage_check.dart';
import 'package:exhale/features/plan/domain/usecases/answer_with_new_plan.dart';
import 'package:exhale/features/plan/domain/usecases/save_plan.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fixed_clock.dart';
import '../../../../helpers/test_database.dart';

LogicalDay _oct(int day) => LogicalDay(2026, 10, day);
LogicalDay _nov(int day) => LogicalDay(2026, 11, day);

void main() {
  late AppDatabase database;
  late LocalPlanRepository plans;
  late LocalStageCheckRepository checks;
  late AnswerWithNewPlan answerWithNewPlan;
  late int habitId;

  final first = ReductionPlan(
    startDay: _oct(12),
    startLimit: 12,
    quitDay: LogicalDay(2027, 1, 4),
  );

  Future<List<StageCheck>> storedChecks() async =>
      (await checks.getChecks(habitId) as Success<List<StageCheck>>).value;

  Future<PlanHistory> history() async =>
      (await plans.getHistory(habitId) as Success<PlanHistory?>).value!;

  AnswerWithNewPlanInput input({
    PlanDraft? draft,
    LogicalDay? windowEnd,
    LogicalDay? planStart,
  }) => (
    habitId: habitId,
    draft:
        draft ??
        PlanDraft(
          startDay: _nov(9),
          startLimit: 11,
          quitDay: _nov(9).addDays(77),
        ),
    planStartDay: planStart ?? _oct(12),
    windowEndDay: windowEnd ?? _nov(8),
  );

  setUp(() async {
    database = createTestDatabase();
    habitId = await insertTestHabit(database);
    plans = LocalPlanRepository(PlanLocalDataSource(database));
    checks = LocalStageCheckRepository(StageCheckLocalDataSource(database));
    answerWithNewPlan = AnswerWithNewPlan(
      AnswerStageCheck(checks, FixedClock(DateTime(2026, 11, 9, 15, 42))),
      SavePlan(plans),
      DriftTransactionRunner(database),
    );
    await plans.savePlan(habitId, first);
    await checks.record(
      habitId,
      StageCheck(
        planStartDay: _oct(12),
        windowEndDay: _nov(8),
        checkDay: _nov(9),
        outcome: StageOutcome.review,
      ),
    );
  });

  tearDown(() => database.close());

  test('saves the new plan and answers the card together', () async {
    final result = await answerWithNewPlan(input());

    expect(result, isA<Success<ReductionPlan>>());
    final saved = await history();
    expect(saved.plans, hasLength(2));
    expect(saved.current.startDay, _nov(9));
    expect(saved.current.startLimit, 11);
    expect(saved.current.stages.first.number, 1);
    // Earlier days keep their own limit.
    expect(saved.limitOn(_nov(8)), 9);
    expect((await storedChecks()).single.answeredAt, isNotNull);
  });

  test('a plan that cannot be saved leaves the card unanswered', () async {
    final result = await answerWithNewPlan(
      input(
        draft: PlanDraft(startDay: _nov(9), startLimit: 0, quitDay: _nov(20)),
      ),
    );

    expect(result, isA<FailureResult<ReductionPlan>>());
    expect(
      (result as FailureResult<ReductionPlan>).failure,
      isA<ValidationFailure>(),
    );
    expect((await history()).plans, hasLength(1));
    expect((await storedChecks()).single.answeredAt, isNull);
  });

  test('an answer that cannot be saved leaves the plan as it was', () async {
    final result = await answerWithNewPlan(input(windowEnd: _nov(1)));

    expect(result, isA<FailureResult<ReductionPlan>>());
    expect((await history()).plans, hasLength(1));
    expect((await storedChecks()).single.answeredAt, isNull);
  });

  test("a plan from the old plan's own start day still answers", () async {
    final result = await answerWithNewPlan(
      input(
        draft: PlanDraft(
          startDay: _oct(12),
          startLimit: 8,
          quitDay: _oct(12).addDays(56),
        ),
      ),
    );

    expect(result, isA<Success<ReductionPlan>>());
    final saved = await history();
    expect(saved.plans, hasLength(1));
    expect(saved.current.startLimit, 8);
  });
}

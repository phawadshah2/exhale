import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/plan/data/datasources/plan_local_data_source.dart';
import 'package:exhale/features/plan/data/datasources/stage_check_local_data_source.dart';
import 'package:exhale/features/plan/data/repositories/local_plan_repository.dart';
import 'package:exhale/features/plan/data/repositories/local_stage_check_repository.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/domain/entities/plan_hold.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/plan/domain/entities/stage_check.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late LocalStageCheckRepository repository;
  late LocalPlanRepository plans;
  late int habit;

  final start = LogicalDay(2026, 10, 12);
  final plan = ReductionPlan(
    startDay: start,
    startLimit: 12,
    quitDay: LogicalDay(2027, 1, 4),
  );

  // Stage 4 ends Nov 8; the check runs on Nov 9.
  final windowEnd = LogicalDay(2026, 11, 8);
  final checkDay = LogicalDay(2026, 11, 9);
  final hold = PlanHold(startDay: checkDay);

  StageCheck check({
    StageOutcome outcome = StageOutcome.hold,
    LogicalDay? window,
    LogicalDay? on,
    DateTime? answeredAt,
  }) => StageCheck(
    planStartDay: start,
    windowEndDay: window ?? windowEnd,
    checkDay: on ?? checkDay,
    outcome: outcome,
    answeredAt: answeredAt,
  );

  setUp(() async {
    database = createTestDatabase();
    repository = LocalStageCheckRepository(StageCheckLocalDataSource(database));
    plans = LocalPlanRepository(PlanLocalDataSource(database));
    habit = await insertTestHabit(database);
    await plans.savePlan(habit, plan);
  });

  tearDown(() => database.close());

  Future<List<StageCheck>> checks() async =>
      (await repository.getChecks(habit) as Success<List<StageCheck>>).value;

  Future<ReductionPlan> currentPlan() async =>
      (await plans.getHistory(habit) as Success<PlanHistory?>).value!.current;

  Future<List<PlanHold>> holds() async => (await currentPlan()).holds;

  group('record', () {
    test('writes the check and the hold together', () async {
      final result = await repository.record(habit, check(), hold: hold);

      expect(result, isA<Success<void>>());
      expect(await checks(), [check()]);
      expect(await holds(), [hold]);
    });

    test('a check with no hold writes only the check', () async {
      await repository.record(habit, check(outcome: StageOutcome.passed));

      expect((await checks()).single.outcome, StageOutcome.passed);
      expect(await holds(), isEmpty);
    });

    test('a duplicate window writes neither and succeeds', () async {
      await repository.record(habit, check(outcome: StageOutcome.passed));

      final result = await repository.record(habit, check(), hold: hold);

      expect(result, isA<Success<void>>());
      expect((await checks()).single.outcome, StageOutcome.passed);
      expect(await holds(), isEmpty);
    });

    test('a failing hold leaves no check behind', () async {
      // The hold already exists, so inserting it again fails.
      await database
          .into(database.planHolds)
          .insert(
            PlanHoldsCompanion.insert(planId: 1, startDay: checkDay.toString()),
          );

      final result = await repository.record(habit, check(), hold: hold);

      expect(result, isA<FailureResult<void>>());
      expect((result as FailureResult<void>).failure, isA<StorageFailure>());
      expect(await checks(), isEmpty);
    });

    test('a plan that does not exist fails and writes nothing', () async {
      final result = await repository.record(
        habit,
        StageCheck(
          planStartDay: LogicalDay(2026, 1, 1),
          windowEndDay: windowEnd,
          checkDay: checkDay,
          outcome: StageOutcome.hold,
        ),
        hold: hold,
      );

      expect(result, isA<FailureResult<void>>());
      expect(await checks(), isEmpty);
      expect(await holds(), isEmpty);
    });

    test('closes the waiting hold card of an earlier window', () async {
      await repository.record(habit, check(), hold: hold);
      final nextWindow = LogicalDay(2026, 11, 22);

      await repository.record(
        habit,
        check(
          outcome: StageOutcome.review,
          window: nextWindow,
          on: LogicalDay(2026, 11, 23),
        ),
        closesHoldWindow: windowEnd,
      );

      final [newest, older] = await checks();
      expect(newest.windowEndDay, nextWindow);
      expect(newest.answeredAt, isNull);
      expect(older.windowEndDay, windowEnd);
      expect(older.answeredAt, isNotNull);
      expect(await holds(), [hold]);
    });

    test('leaves an answered check as it was when closing', () async {
      final answered = DateTime(2026, 11, 9, 20);
      await repository.record(habit, check(answeredAt: answered), hold: hold);

      await repository.record(
        habit,
        check(
          outcome: StageOutcome.review,
          window: LogicalDay(2026, 11, 22),
          on: LogicalDay(2026, 11, 23),
        ),
        closesHoldWindow: windowEnd,
      );

      expect((await checks()).last.answeredAt, answered);
    });
  });

  group('answer', () {
    test('sets the time and leaves the hold', () async {
      await repository.record(habit, check(), hold: hold);
      final at = DateTime(2026, 11, 9, 21, 30);

      final result = await repository.answer(habit, start, windowEnd, at);

      expect(result, isA<Success<void>>());
      expect((await checks()).single.answeredAt, at);
      expect(await holds(), [hold]);
    });
  });

  group('keepOriginalDate', () {
    test('deletes the hold and answers the check together', () async {
      await repository.record(habit, check(), hold: hold);
      final at = DateTime(2026, 11, 9, 21, 30);

      final result = await repository.keepOriginalDate(
        habit,
        start,
        windowEnd,
        checkDay,
        at,
      );

      expect(result, isA<Success<void>>());
      expect(await holds(), isEmpty);
      expect((await checks()).single.answeredAt, at);
      expect((await currentPlan()).quitDay, plan.quitDay);
    });

    test('leaves both alone when it fails', () async {
      await repository.record(habit, check(), hold: hold);
      // A check that is not there: the answer matches no row.
      final result = await repository.keepOriginalDate(
        habit,
        start,
        LogicalDay(2026, 12, 1),
        checkDay,
        DateTime(2026, 11, 9),
      );

      expect(result, isA<FailureResult<void>>());
      expect(await holds(), [hold]);
      expect((await checks()).single.answeredAt, isNull);
    });
  });

  group('watchChecks', () {
    test('lists the newest check first and emits on a write', () async {
      final emissions = <List<StageCheck>>[];
      final sub = repository.watchChecks(habit).listen(emissions.add);
      await pumpEventQueue();

      await repository.record(habit, check(outcome: StageOutcome.passed));
      await repository.record(
        habit,
        check(
          window: LogicalDay(2026, 11, 15),
          on: LogicalDay(2026, 11, 16),
          outcome: StageOutcome.passed,
        ),
      );
      await pumpEventQueue();
      await sub.cancel();

      expect(emissions.first, isEmpty);
      expect(emissions.last.map((c) => c.windowEndDay), [
        LogicalDay(2026, 11, 15),
        windowEnd,
      ]);
    });

    test('only lists the habit asked for', () async {
      await repository.record(habit, check(), hold: hold);
      final other = await insertTestHabit(database);

      expect(
        (await repository.getChecks(other) as Success<List<StageCheck>>).value,
        isEmpty,
      );
    });
  });
}

import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/core/data/local/database/drift_transaction_runner.dart';
import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/day_boundary.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/plan/data/datasources/plan_local_data_source.dart';
import 'package:exhale/features/plan/data/datasources/stage_check_local_data_source.dart';
import 'package:exhale/features/plan/data/repositories/local_plan_repository.dart';
import 'package:exhale/features/plan/data/repositories/local_stage_check_repository.dart';
import 'package:exhale/features/plan/domain/entities/plan_hold.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/plan/domain/entities/stage_check.dart';
import 'package:exhale/features/plan/domain/repositories/stage_check_repository.dart';
import 'package:exhale/features/plan/domain/usecases/run_stage_check.dart';
import 'package:exhale/features/tracking/data/datasources/habit_log_local_data_source.dart';
import 'package:exhale/features/tracking/data/repositories/local_habit_log_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_database.dart';

LogicalDay _oct(int day) => LogicalDay(2026, 10, day);
LogicalDay _nov(int day) => LogicalDay(2026, 11, day);

/// Reads fail while [failReads] is set; everything else goes to [inner].
class _FlakyChecks implements StageCheckRepository {
  _FlakyChecks(this.inner);
  final StageCheckRepository inner;
  bool failReads = false;

  @override
  Future<Result<List<StageCheck>>> getChecks(int habitId) async => failReads
      ? const FailureResult<List<StageCheck>>(StorageFailure())
      : await inner.getChecks(habitId);

  @override
  Stream<List<StageCheck>> watchChecks(int habitId) =>
      inner.watchChecks(habitId);

  @override
  Future<Result<void>> record(
    int habitId,
    StageCheck check, {
    PlanHold? hold,
    LogicalDay? closesHoldWindow,
  }) => inner.record(
    habitId,
    check,
    hold: hold,
    closesHoldWindow: closesHoldWindow,
  );

  @override
  Future<Result<void>> answer(
    int habitId,
    LogicalDay planStartDay,
    LogicalDay windowEndDay,
    DateTime at,
  ) => inner.answer(habitId, planStartDay, windowEndDay, at);

  @override
  Future<Result<void>> keepOriginalDate(
    int habitId,
    LogicalDay planStartDay,
    LogicalDay windowEndDay,
    LogicalDay holdStart,
    DateTime at,
  ) => inner.keepOriginalDate(
    habitId,
    planStartDay,
    windowEndDay,
    holdStart,
    at,
  );
}

void main() {
  late AppDatabase database;
  late LocalPlanRepository plans;
  late LocalHabitLogRepository logs;
  late _FlakyChecks checks;
  late RunStageCheck run;
  late int habitId;

  /// 12 a day from Oct 12, quit Jan 4: stage 4 (9 a day) ends Nov 8.
  final plan = ReductionPlan(
    startDay: _oct(12),
    startLimit: 12,
    quitDay: LogicalDay(2027, 1, 4),
  );

  Future<void> logDay(LogicalDay day, int count) async {
    for (var i = 0; i < count; i++) {
      await logs.addLog(
        habitId: habitId,
        loggedAt: DateTime(day.year, day.month, day.day, 12, i),
      );
    }
  }

  /// Stage 4 at its limit except two days of 12.
  Future<void> logFailingStage4() async {
    for (var d = 2; d <= 8; d++) {
      await logDay(_nov(d), d == 3 || d == 4 ? 12 : 9);
    }
  }

  Future<Result<void>> runOn(LogicalDay today, {int? forHabit}) => run((
    habitId: forHabit ?? habitId,
    today: today,
    boundary: const DayBoundary(),
  ));

  Future<List<StageCheckRow>> storedChecks() =>
      database.select(database.stageChecks).get();
  Future<List<PlanHoldRow>> storedHolds() =>
      database.select(database.planHolds).get();

  setUp(() async {
    database = createTestDatabase();
    habitId = await insertTestHabit(database);
    plans = LocalPlanRepository(PlanLocalDataSource(database));
    logs = LocalHabitLogRepository(HabitLogLocalDataSource(database));
    checks = _FlakyChecks(
      LocalStageCheckRepository(StageCheckLocalDataSource(database)),
    );
    run = RunStageCheck(plans, checks, logs, DriftTransactionRunner(database));
    await plans.savePlan(habitId, plan);
  });

  tearDown(() => database.close());

  test('a failed check stores a hold and its plan_holds row', () async {
    await logFailingStage4();

    final result = await runOn(_nov(9));

    expect(result, isA<Success<void>>());
    final stored = await storedChecks();
    expect(stored, hasLength(1));
    expect(stored.single.outcome, 'hold');
    expect(stored.single.windowEndDay, '2026-11-08');
    expect(stored.single.checkDay, '2026-11-09');
    expect(stored.single.answeredAt, isNull);
    final holds = await storedHolds();
    expect(holds, hasLength(1));
    expect(holds.single.startDay, '2026-11-09');
    expect(holds.single.days, 7);
  });

  test('a pass stores only the check', () async {
    await logDay(_nov(5), 9);

    await runOn(_nov(9));

    expect((await storedChecks()).single.outcome, 'passed');
    expect(await storedHolds(), isEmpty);
  });

  test('nothing is stored when no check is due', () async {
    await runOn(_oct(18));

    expect(await storedChecks(), isEmpty);
  });

  test('running again on the same day stores nothing new', () async {
    await logFailingStage4();

    await runOn(_nov(9));
    await runOn(_nov(9));

    expect(await storedChecks(), hasLength(1));
    expect(await storedHolds(), hasLength(1));
  });

  test('two calls at once store one check and one hold', () async {
    await logFailingStage4();

    final results = await Future.wait([runOn(_nov(9)), runOn(_nov(9))]);

    expect(results, everyElement(isA<Success<void>>()));
    expect(await storedChecks(), hasLength(1));
    expect(await storedHolds(), hasLength(1));
  });

  test('a read failure stores nothing, and the next run works', () async {
    await logFailingStage4();
    checks.failReads = true;

    final failed = await runOn(_nov(9));

    expect(failed, isA<FailureResult<void>>());
    expect((failed as FailureResult<void>).failure, isA<StorageFailure>());
    expect(await storedChecks(), isEmpty);
    expect(await storedHolds(), isEmpty);

    checks.failReads = false;
    expect(await runOn(_nov(9)), isA<Success<void>>());
    expect(await storedChecks(), hasLength(1));
  });

  test('a habit with no plan stores nothing', () async {
    final other = await insertTestHabit(database);

    final result = await runOn(_nov(9), forHabit: other);

    expect(result, isA<Success<void>>());
    expect(await storedChecks(), isEmpty);
  });

  test('a habit that does not exist stores nothing', () async {
    final result = await runOn(_nov(9), forHabit: 999);

    expect(result, isA<Success<void>>());
    expect(await storedChecks(), isEmpty);
  });

  test('a second failure answers the waiting hold card', () async {
    await logFailingStage4();
    await runOn(_nov(9));
    // Stage 4 now runs to Nov 15 and stage 5 (8 a day) to Nov 22.
    for (var d = 16; d <= 22; d++) {
      await logDay(_nov(d), d == 17 || d == 18 ? 12 : 8);
    }

    await runOn(_nov(23));

    final stored = await storedChecks();
    expect(stored.map((c) => c.outcome), containsAll(['hold', 'review']));
    final hold = stored.singleWhere((c) => c.outcome == 'hold');
    expect(hold.answeredAt, isNotNull);
    expect(await storedHolds(), hasLength(1));
  });
}

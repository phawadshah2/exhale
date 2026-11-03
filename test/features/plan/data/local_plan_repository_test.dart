import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/plan/data/datasources/plan_local_data_source.dart';
import 'package:exhale/features/plan/data/repositories/local_plan_repository.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/domain/entities/plan_hold.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late LocalPlanRepository repository;

  final oct15 = LogicalDay(2026, 10, 15);
  final first = ReductionPlan(
    startDay: oct15,
    startLimit: 9,
    quitDay: oct15.addDays(63),
  );
  ReductionPlan planFrom(LogicalDay start, int limit) => ReductionPlan(
    startDay: start,
    startLimit: limit,
    quitDay: start.addDays(40),
  );

  late int habit;

  setUp(() async {
    database = createTestDatabase();
    repository = LocalPlanRepository(PlanLocalDataSource(database));
    habit = await insertTestHabit(database);
  });

  tearDown(() => database.close());

  PlanHistory? historyOf(Result<PlanHistory?> result) =>
      (result as Success<PlanHistory?>).value;

  test('has no history before the first plan', () async {
    expect(historyOf(await repository.getHistory(habit)), isNull);
    expect(await repository.watchHistory(habit).first, isNull);
  });

  test('saves and reads back a plan with every field', () async {
    final plan = ReductionPlan(
      startDay: oct15,
      startLimit: 12,
      quitDay: LogicalDay(2027, 1, 31),
    );

    expect(await repository.savePlan(habit, plan), isA<Success<void>>());
    expect(historyOf(await repository.getHistory(habit))!.plans, [plan]);
  });

  test('a later plan is added on top of history', () async {
    final restart = planFrom(oct15.addDays(14), 5);

    await repository.savePlan(habit, first);
    await repository.savePlan(habit, restart);

    expect(historyOf(await repository.getHistory(habit))!.plans, [
      first,
      restart,
    ]);
  });

  test('a plan on the same or an earlier day replaces later plans', () async {
    final later = planFrom(oct15.addDays(14), 5);
    final earlier = planFrom(oct15.addDays(7), 6);

    await repository.savePlan(habit, first);
    await repository.savePlan(habit, later);
    await repository.savePlan(habit, earlier);
    expect(historyOf(await repository.getHistory(habit))!.plans, [
      first,
      earlier,
    ]);

    final sameDay = planFrom(oct15.addDays(7), 4);
    await repository.savePlan(habit, sameDay);
    expect(historyOf(await repository.getHistory(habit))!.plans, [
      first,
      sameDay,
    ]);
  });

  test('watchHistory emits after each save', () async {
    final emissions = <PlanHistory?>[];
    final sub = repository.watchHistory(habit).listen(emissions.add);

    await pumpEventQueue();
    await repository.savePlan(habit, first);
    await pumpEventQueue();
    await sub.cancel();

    expect(emissions.first, isNull);
    expect(emissions.last!.current, first);
  });

  Future<int> planId(LogicalDay start) async => (await (database.select(
    database.plans,
  )..where((row) => row.startDay.equals(start.toString()))).getSingle()).id;

  Future<void> addHold(int plan, LogicalDay start, {int days = 7}) => database
      .into(database.planHolds)
      .insert(
        PlanHoldsCompanion.insert(
          planId: plan,
          startDay: start.toString(),
          days: Value(days),
        ),
      );

  test('a plan reads back its holds, earliest first', () async {
    await repository.savePlan(habit, first);
    final id = await planId(oct15);
    await addHold(id, oct15.addDays(28));
    await addHold(id, oct15.addDays(14), days: 3);

    final [plan] = historyOf(await repository.getHistory(habit))!.plans;

    expect(plan.holds, [
      PlanHold(startDay: oct15.addDays(14), days: 3),
      PlanHold(startDay: oct15.addDays(28)),
    ]);
    expect(plan.agreedQuitDay, oct15.addDays(63));
    expect(plan.quitDay, oct15.addDays(73));
  });

  test('watchHistory emits when a hold is added', () async {
    await repository.savePlan(habit, first);
    final emissions = <PlanHistory?>[];
    final sub = repository.watchHistory(habit).listen(emissions.add);
    await pumpEventQueue();

    await addHold(await planId(oct15), oct15.addDays(14));
    await pumpEventQueue();
    await sub.cancel();

    expect(emissions.first!.current.holds, isEmpty);
    expect(emissions.last!.current.holds, [
      PlanHold(startDay: oct15.addDays(14)),
    ]);
  });

  test('a replan removes the holds and checks of the plans it drops', () async {
    final later = planFrom(oct15.addDays(14), 5);
    await repository.savePlan(habit, first);
    await repository.savePlan(habit, later);
    final laterId = await planId(later.startDay);
    final firstId = await planId(oct15);
    await addHold(firstId, oct15.addDays(7));
    await addHold(laterId, later.startDay.addDays(7));
    for (final plan in [firstId, laterId]) {
      await database
          .into(database.stageChecks)
          .insert(
            StageChecksCompanion.insert(
              planId: plan,
              windowEndDay: '2026-11-01',
              checkDay: '2026-11-02',
              outcome: 'hold',
            ),
          );
    }

    final earlier = planFrom(oct15.addDays(7), 6);
    expect(await repository.savePlan(habit, earlier), isA<Success<void>>());

    final holds = await database.select(database.planHolds).get();
    final checks = await database.select(database.stageChecks).get();
    expect(holds.map((hold) => hold.planId), [firstId]);
    expect(checks.map((check) => check.planId), [firstId]);
  });

  test('plans of two habits do not replace each other', () async {
    final other = await insertTestHabit(database, kind: HabitKind.caffeine);
    final caffeine = planFrom(oct15, 4);

    await repository.savePlan(habit, first);
    await repository.savePlan(other, caffeine);

    expect(historyOf(await repository.getHistory(habit))!.plans, [first]);
    expect(historyOf(await repository.getHistory(other))!.plans, [caffeine]);
  });
}

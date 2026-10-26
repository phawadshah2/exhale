import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/plan/data/datasources/plan_local_data_source.dart';
import 'package:exhale/features/plan/data/repositories/local_plan_repository.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
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

  test('plans of two habits do not replace each other', () async {
    final other = await insertTestHabit(database, kind: HabitKind.caffeine);
    final caffeine = planFrom(oct15, 4);

    await repository.savePlan(habit, first);
    await repository.savePlan(other, caffeine);

    expect(historyOf(await repository.getHistory(habit))!.plans, [first]);
    expect(historyOf(await repository.getHistory(other))!.plans, [caffeine]);
  });
}

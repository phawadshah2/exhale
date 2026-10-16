import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
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
  final first = ReductionPlan(startDay: oct15, startLimit: 9);

  setUp(() {
    database = createTestDatabase();
    repository = LocalPlanRepository(PlanLocalDataSource(database));
  });

  tearDown(() => database.close());

  PlanHistory? historyOf(Result<PlanHistory?> result) =>
      (result as Success<PlanHistory?>).value;

  test('has no history before the first plan', () async {
    expect(historyOf(await repository.getHistory()), isNull);
    expect(await repository.watchHistory().first, isNull);
  });

  test('saves and reads back a plan with every field', () async {
    final plan = ReductionPlan(
      startDay: oct15,
      startLimit: 12,
      stepDays: 5,
      targetLimit: 2,
    );

    expect(await repository.savePlan(plan), isA<Success<void>>());
    expect(historyOf(await repository.getHistory())!.plans, [plan]);
  });

  test('a later plan is added on top of history', () async {
    final restart = ReductionPlan(startDay: oct15.addDays(14), startLimit: 5);

    await repository.savePlan(first);
    await repository.savePlan(restart);

    expect(historyOf(await repository.getHistory())!.plans, [first, restart]);
  });

  test('a plan on the same or an earlier day replaces later plans', () async {
    final later = ReductionPlan(startDay: oct15.addDays(14), startLimit: 5);
    final earlier = ReductionPlan(startDay: oct15.addDays(7), startLimit: 6);

    await repository.savePlan(first);
    await repository.savePlan(later);
    await repository.savePlan(earlier);
    expect(historyOf(await repository.getHistory())!.plans, [first, earlier]);

    final sameDay = ReductionPlan(startDay: oct15.addDays(7), startLimit: 4);
    await repository.savePlan(sameDay);
    expect(historyOf(await repository.getHistory())!.plans, [first, sameDay]);
  });

  test('watchHistory emits after each save', () async {
    final emissions = <PlanHistory?>[];
    final sub = repository.watchHistory().listen(emissions.add);

    await pumpEventQueue();
    await repository.savePlan(first);
    await pumpEventQueue();
    await sub.cancel();

    expect(emissions.first, isNull);
    expect(emissions.last!.current, first);
  });
}

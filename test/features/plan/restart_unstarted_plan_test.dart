import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/plan/domain/repositories/plan_repository.dart';
import 'package:exhale/features/plan/domain/usecases/restart_unstarted_plan.dart';
import 'package:exhale/features/tracking/domain/repositories/habit_log_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/pump_app.dart';

void main() {
  final saved = LogicalDay(2026, 11, 1);
  final today = LogicalDay(2026, 11, 13);
  late int habitId;

  setUp(() async {
    await setUpTestDependencies(FixedClock(DateTime(2026, 11, 13, 9)));
    habitId = await seedHabit(
      PlanDraft(startDay: saved, startLimit: 6, quitDay: saved.addDays(42)),
    );
    // A later plan, so there is more than one to replace.
    await sl<PlanRepository>().savePlan(
      habitId,
      ReductionPlan(
        startDay: saved.addDays(4),
        startLimit: 6,
        quitDay: saved.addDays(60),
      ),
    );
  });

  tearDown(InjectionContainer.reset);

  Future<List<ReductionPlan>> plans() async =>
      ((await sl<PlanRepository>().getHistory(
        habitId,
      )) as Success<PlanHistory?>).value!.plans;

  final draft = PlanDraft(
    startDay: today,
    startLimit: 6,
    quitDay: today.addDays(42),
  );

  test('a habit with no logs gets the draft as its only plan', () async {
    final result = await sl<RestartUnstartedPlan>()((
      habitId: habitId,
      draft: draft,
    ));

    expect(result, isA<Success<void>>());
    expect(await plans(), [
      ReductionPlan(startDay: today, startLimit: 6, quitDay: today.addDays(42)),
    ]);
  });

  test('a habit with logs keeps its plans', () async {
    await sl<HabitLogRepository>().addLog(
      habitId: habitId,
      loggedAt: DateTime(2026, 11, 2, 10),
    );
    final before = await plans();

    final result = await sl<RestartUnstartedPlan>()((
      habitId: habitId,
      draft: draft,
    ));

    expect(result, isA<Success<void>>());
    expect(await plans(), before);
    expect(before, hasLength(2));
  });

  test('an invalid draft writes nothing', () async {
    final before = await plans();

    final result = await sl<RestartUnstartedPlan>()((
      habitId: habitId,
      draft: PlanDraft(startDay: today, startLimit: 6, quitDay: today),
    ));

    expect(result, isA<FailureResult<void>>());
    expect(await plans(), before);
  });
}

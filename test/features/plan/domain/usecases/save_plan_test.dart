import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/plan/data/datasources/plan_local_data_source.dart';
import 'package:exhale/features/plan/data/repositories/local_plan_repository.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/plan/domain/usecases/save_plan.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late LocalPlanRepository repository;
  late SavePlan savePlan;

  final today = LogicalDay(2026, 10, 16);

  setUp(() {
    database = createTestDatabase();
    repository = LocalPlanRepository(PlanLocalDataSource(database));
    savePlan = SavePlan(repository);
  });

  tearDown(() => database.close());

  Future<String> rejection(PlanDraft draft) async {
    final result = await savePlan(draft);
    return ((result as FailureResult<ReductionPlan>).failure
            as ValidationFailure)
        .message;
  }

  test('saves a valid draft as the current plan', () async {
    final result = await savePlan(PlanDraft(startDay: today, startLimit: 9));

    final plan = (result as Success<ReductionPlan>).value;
    final history =
        (await repository.getHistory() as Success<PlanHistory?>).value!;
    expect(plan, ReductionPlan(startDay: today, startLimit: 9));
    expect(history.current, plan);
  });

  test('rejects out-of-range values without saving', () async {
    expect(
      await rejection(PlanDraft(startDay: today, startLimit: 0)),
      contains('Daily amount'),
    );
    expect(
      await rejection(PlanDraft(startDay: today, startLimit: 81)),
      contains('Daily amount'),
    );
    expect(
      await rejection(PlanDraft(startDay: today, startLimit: 9, stepDays: 0)),
      contains('pace'),
    );
    expect(
      await rejection(PlanDraft(startDay: today, startLimit: 9, stepDays: 31)),
      contains('pace'),
    );
    expect(
      await rejection(
        PlanDraft(startDay: today, startLimit: 9, targetLimit: 9),
      ),
      contains('lower'),
    );
    expect(
      await rejection(
        PlanDraft(startDay: today, startLimit: 9, targetLimit: -1),
      ),
      contains('negative'),
    );
    expect(
      (await repository.getHistory() as Success<PlanHistory?>).value,
      isNull,
    );
  });
}

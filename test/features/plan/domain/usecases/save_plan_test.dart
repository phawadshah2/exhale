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
import 'package:exhale/features/plan/domain/validation/plan_validation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late LocalPlanRepository repository;
  late SavePlan savePlan;

  final today = LogicalDay(2026, 10, 19);

  PlanDraft draft({int limit = 9, int days = 56}) => PlanDraft(
    startDay: today,
    startLimit: limit,
    quitDay: today.addDays(days),
  );

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
    final result = await savePlan(draft());

    final plan = (result as Success<ReductionPlan>).value;
    final history =
        (await repository.getHistory() as Success<PlanHistory?>).value!;
    expect(
      plan,
      ReductionPlan(startDay: today, startLimit: 9, quitDay: today.addDays(56)),
    );
    expect(history.current, plan);
  });

  test('rejects out-of-range values without saving', () async {
    expect(await rejection(draft(limit: 0)), contains('Daily amount'));
    expect(await rejection(draft(limit: 81)), contains('Daily amount'));
    expect(await rejection(draft(days: 2)), contains('at least 3 days'));
    expect(await rejection(draft(days: -1)), contains('at least 3 days'));
    expect(await rejection(draft(days: 366)), contains('within a year'));
    expect(
      (await repository.getHistory() as Success<PlanHistory?>).value,
      isNull,
    );
  });

  test('accepts the boundaries', () async {
    expect(await savePlan(draft(days: 3)), isA<Success<ReductionPlan>>());
    expect(await savePlan(draft(days: 365)), isA<Success<ReductionPlan>>());
  });

  test('steep plans are allowed but flagged', () {
    expect(PlanValidation.isSteep(draft(days: 5)), isTrue);
    expect(PlanValidation.isSteep(draft(days: 9)), isFalse);
    expect(PlanValidation.validate(draft(days: 5)), isNull);
  });
}

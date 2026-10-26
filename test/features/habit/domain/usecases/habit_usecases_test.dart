import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/core/data/local/database/drift_transaction_runner.dart';
import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/habit/data/datasources/habit_local_data_source.dart';
import 'package:exhale/features/habit/data/repositories/local_habit_repository.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/domain/entities/habit_draft.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:exhale/features/habit/domain/usecases/add_habit.dart';
import 'package:exhale/features/habit/domain/usecases/archive_habit.dart';
import 'package:exhale/features/habit/domain/usecases/start_tracking.dart';
import 'package:exhale/features/habit/domain/usecases/update_habit.dart';
import 'package:exhale/features/plan/data/datasources/plan_local_data_source.dart';
import 'package:exhale/features/plan/data/repositories/local_plan_repository.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/plan/domain/repositories/plan_repository.dart';
import 'package:exhale/features/plan/domain/usecases/save_plan.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fixed_clock.dart';
import '../../../../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late LocalHabitRepository repository;
  late FixedClock clock;
  late AddHabit addHabit;

  setUp(() {
    database = createTestDatabase();
    repository = LocalHabitRepository(HabitLocalDataSource(database));
    clock = FixedClock(DateTime(2026, 10, 16, 15, 42));
    addHabit = AddHabit(repository, clock);
  });

  tearDown(() => database.close());

  Future<TrackedHabit> added(HabitDraft draft) async =>
      (await addHabit(draft) as Success<TrackedHabit>).value;

  group('AddHabit', () {
    test('stamps createdAt from the clock and trims the reason', () async {
      final habit = await added(
        const HabitDraft(habit: Habit.vaping, reason: '  For my lungs '),
      );

      expect(habit.createdAt, DateTime(2026, 10, 16, 15, 42));
      expect(habit.reason, 'For my lungs');
    });

    test('stores a blank reason as null', () async {
      expect(
        (await added(const HabitDraft(habit: Habit.vaping, reason: '   ')))
            .reason,
        isNull,
      );
    });

    test('rejects an out-of-range price or container size', () async {
      const invalid = [
        HabitDraft(habit: Habit.vaping, priceCents: -1),
        HabitDraft(habit: Habit.vaping, priceCents: 100001),
        HabitDraft(habit: Habit.vaping, unitsPerContainer: 0),
        HabitDraft(habit: Habit.vaping, unitsPerContainer: 101),
      ];
      for (final draft in invalid) {
        expect(
          (await addHabit(draft) as FailureResult<TrackedHabit>).failure,
          isA<ValidationFailure>(),
          reason: '$draft',
        );
      }
      expect(await repository.watchActive().first, isEmpty);
    });
  });

  test('UpdateHabit validates and trims like AddHabit', () async {
    final habit = await added(const HabitDraft(habit: Habit.vaping));
    final updateHabit = UpdateHabit(repository);

    expect(
      await updateHabit(habit.copyWith(priceCents: () => -5)),
      isA<FailureResult<void>>(),
    );
    await updateHabit(habit.copyWith(reason: () => ' Sleep better '));

    expect(
      (await repository.watchActive().first).single.reason,
      'Sleep better',
    );
  });

  test('ArchiveHabit stamps archivedAt from the clock', () async {
    final habit = await added(const HabitDraft(habit: Habit.vaping));
    clock.current = DateTime(2026, 10, 20, 8);

    await ArchiveHabit(repository, clock)(habit.id);

    final row = await database.select(database.habits).getSingle();
    expect(row.archivedAt, DateTime(2026, 10, 20, 8));
  });

  group('StartTracking', () {
    late PlanRepository plans;

    StartTracking startTracking({PlanRepository? planRepository}) =>
        StartTracking(
          addHabit,
          SavePlan(planRepository ?? plans),
          DriftTransactionRunner(database),
        );

    final today = LogicalDay(2026, 10, 16);
    final plan = PlanDraft(
      startDay: today,
      startLimit: 9,
      quitDay: today.addDays(63),
    );

    setUp(() => plans = LocalPlanRepository(PlanLocalDataSource(database)));

    test('adds the habit with its plan', () async {
      final result = await startTracking()((
        habit: const HabitDraft(habit: Habit.vaping),
        plan: plan,
      ));

      final habit = (result as Success<TrackedHabit>).value;
      final history =
          (await plans.getHistory(habit.id) as Success<PlanHistory?>).value;
      expect(history!.current.startLimit, 9);
    });

    test('keeps no habit when the plan is invalid', () async {
      final result = await startTracking()((
        habit: const HabitDraft(habit: Habit.vaping),
        plan: plan.copyWith(startLimit: 0),
      ));

      expect(
        (result as FailureResult<TrackedHabit>).failure,
        isA<ValidationFailure>(),
      );
      expect(await database.select(database.habits).get(), isEmpty);
    });

    test('keeps no habit when the plan cannot be stored', () async {
      final result = await startTracking(planRepository: _FailingPlans())((
        habit: const HabitDraft(habit: Habit.vaping),
        plan: plan,
      ));

      expect(
        (result as FailureResult<TrackedHabit>).failure,
        isA<StorageFailure>(),
      );
      expect(await database.select(database.habits).get(), isEmpty);
    });
  });
}

class _FailingPlans implements PlanRepository {
  @override
  Future<Result<void>> savePlan(int habitId, ReductionPlan plan) async =>
      const FailureResult<void>(StorageFailure());

  @override
  Future<Result<PlanHistory?>> getHistory(int habitId) async =>
      const Success<PlanHistory?>(null);

  @override
  Stream<PlanHistory?> watchHistory(int habitId) => Stream.value(null);
}

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
import 'package:exhale/features/habit/domain/repositories/habit_repository.dart';
import 'package:exhale/features/habit/domain/usecases/add_habit.dart';
import 'package:exhale/features/habit/domain/usecases/archive_habit.dart';
import 'package:exhale/features/habit/domain/usecases/change_habit.dart';
import 'package:exhale/features/habit/domain/usecases/start_tracking.dart';
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
  late LocalHabitRepository habits;
  late PlanRepository plans;
  late FixedClock clock;
  late int oldId;

  final today = LogicalDay(2026, 10, 16);
  final plan = PlanDraft(
    startDay: today,
    startLimit: 9,
    quitDay: today.addDays(63),
  );

  ChangeHabit changeHabit({
    HabitRepository? archiveWith,
    PlanRepository? planRepository,
  }) {
    final transactions = DriftTransactionRunner(database);
    return ChangeHabit(
      habits,
      ArchiveHabit(archiveWith ?? habits, clock),
      StartTracking(
        AddHabit(habits, clock),
        SavePlan(planRepository ?? plans),
        transactions,
      ),
      transactions,
    );
  }

  ChangeHabitInput smoking({PlanDraft? draft}) => (
    replacedHabitId: oldId,
    habit: const HabitDraft(habit: Habit.smoking),
    plan: draft ?? plan,
  );

  Future<List<TrackedHabit>> active() async =>
      (await habits.getActive() as Success<List<TrackedHabit>>).value;

  setUp(() async {
    database = createTestDatabase();
    habits = LocalHabitRepository(HabitLocalDataSource(database));
    plans = LocalPlanRepository(PlanLocalDataSource(database));
    clock = FixedClock(DateTime(2026, 10, 16, 15, 42));
    final started = await StartTracking(
      AddHabit(habits, clock),
      SavePlan(plans),
      DriftTransactionRunner(database),
    )((habit: const HabitDraft(habit: Habit.vaping), plan: plan));
    oldId = (started as Success<TrackedHabit>).value.id;
  });

  tearDown(() => database.close());

  test('archives the old habit and starts the new one with a plan', () async {
    final result = await changeHabit()(smoking());

    final added = (result as Success<TrackedHabit>).value;
    expect(added.habit, Habit.smoking);
    expect((await active()).map((h) => h.id), [added.id]);
    final old = await (database.select(
      database.habits,
    )..where((row) => row.id.equals(oldId))).getSingle();
    expect(old.archivedAt, DateTime(2026, 10, 16, 15, 42));
    final history =
        (await plans.getHistory(added.id) as Success<PlanHistory?>).value;
    expect(history!.current.startLimit, 9);
  });

  test(
    'a failed plan save rolls back and keeps the old habit active',
    () async {
      final result = await changeHabit(planRepository: _FailingPlans())(
        smoking(),
      );

      expect(
        (result as FailureResult<TrackedHabit>).failure,
        isA<StorageFailure>(),
      );
      expect((await active()).map((h) => h.id), [oldId]);
      expect(await database.select(database.habits).get(), hasLength(1));
    },
  );

  test('an invalid plan rolls back and keeps the old habit active', () async {
    final result = await changeHabit()(
      smoking(draft: plan.copyWith(startLimit: 0)),
    );

    expect(
      (result as FailureResult<TrackedHabit>).failure,
      isA<ValidationFailure>(),
    );
    expect((await active()).map((h) => h.id), [oldId]);
    expect(await database.select(database.habits).get(), hasLength(1));
  });

  test('a failed archive starts nothing', () async {
    final result = await changeHabit(archiveWith: _FailingArchive(habits))(
      smoking(),
    );

    expect(
      (result as FailureResult<TrackedHabit>).failure,
      isA<StorageFailure>(),
    );
    expect((await active()).map((h) => h.id), [oldId]);
    expect(await database.select(database.habits).get(), hasLength(1));
  });

  test('a habit no longer active is not replaced twice', () async {
    final first = await changeHabit()(smoking());
    final added = (first as Success<TrackedHabit>).value;

    final second = await changeHabit()(smoking());

    expect(
      (second as FailureResult<TrackedHabit>).failure,
      isA<NotFoundFailure>(),
    );
    expect((await active()).map((h) => h.id), [added.id]);
    expect(await database.select(database.habits).get(), hasLength(2));
  });

  test('choosing the old habit again later adds a new row', () async {
    final first = await changeHabit()(smoking());
    final smokingId = (first as Success<TrackedHabit>).value.id;

    final back = await changeHabit()((
      replacedHabitId: smokingId,
      habit: const HabitDraft(habit: Habit.vaping),
      plan: plan,
    ));

    final vaping = (back as Success<TrackedHabit>).value;
    expect(vaping.id, isNot(oldId));
    expect((await active()).map((h) => h.id), [vaping.id]);
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

class _FailingArchive implements HabitRepository {
  const _FailingArchive(this._inner);
  final HabitRepository _inner;

  @override
  Stream<List<TrackedHabit>> watchActive() => _inner.watchActive();

  @override
  Future<Result<List<TrackedHabit>>> getActive() => _inner.getActive();

  @override
  Future<Result<TrackedHabit>> add(
    HabitDraft draft, {
    required DateTime createdAt,
  }) => _inner.add(draft, createdAt: createdAt);

  @override
  Future<Result<void>> update(TrackedHabit habit) => _inner.update(habit);

  @override
  Future<Result<void>> archive(int id, {required DateTime at}) async =>
      const FailureResult<void>(StorageFailure());
}

import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/features/habit/data/datasources/habit_local_data_source.dart';
import 'package:exhale/features/habit/data/repositories/local_habit_repository.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/domain/entities/habit_draft.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late LocalHabitRepository repository;

  setUp(() {
    database = createTestDatabase();
    repository = LocalHabitRepository(HabitLocalDataSource(database));
  });

  tearDown(() => database.close());

  Future<TrackedHabit> add(
    Habit habit, {
    required DateTime createdAt,
    String? reason,
    int? priceCents,
  }) async => (await repository.add(
    HabitDraft(habit: habit, reason: reason, priceCents: priceCents),
    createdAt: createdAt,
  ) as Success<TrackedHabit>).value;

  Future<List<TrackedHabit>> getActive() async =>
      (await repository.getActive() as Success<List<TrackedHabit>>).value;

  test('add stores the draft and returns it with an id', () async {
    final habit = await add(
      Habit.vaping,
      createdAt: DateTime(2026, 10, 16, 9),
      reason: 'For my lungs',
      priceCents: 1200,
    );

    expect(habit.id, greaterThan(0));
    expect(habit.habit, Habit.vaping);
    expect(habit.reason, 'For my lungs');
    expect(habit.priceCents, 1200);
    expect(habit.unitsPerContainer, 20);
    expect(habit.createdAt, DateTime(2026, 10, 16, 9));
    expect(habit.archivedAt, isNull);
  });

  test('watchActive emits active habits ordered by createdAt', () async {
    final later = await add(Habit.caffeine, createdAt: DateTime(2026, 10, 18));
    final earlier = await add(Habit.vaping, createdAt: DateTime(2026, 10, 16));

    expect(await repository.watchActive().first, [earlier, later]);
  });

  test('archive hides a habit but keeps its row', () async {
    final vaping = await add(Habit.vaping, createdAt: DateTime(2026, 10, 16));
    final caffeine = await add(
      Habit.caffeine,
      createdAt: DateTime(2026, 10, 17),
    );

    final result = await repository.archive(
      vaping.id,
      at: DateTime(2026, 10, 20),
    );

    expect(result, isA<Success<void>>());
    expect(await getActive(), [caffeine]);
    final row = await (database.select(
      database.habits,
    )..where((h) => h.id.equals(vaping.id))).getSingle();
    expect(row.archivedAt, DateTime(2026, 10, 20));
  });

  test('update persists reason and price', () async {
    final habit = await add(Habit.vaping, createdAt: DateTime(2026, 10, 16));

    await repository.update(
      habit.copyWith(reason: () => 'Run again', priceCents: () => 900),
    );

    final [stored] = await getActive();
    expect(stored.reason, 'Run again');
    expect(stored.priceCents, 900);
  });

  test('update and archive of a missing habit fail with NotFound', () async {
    final missing = TrackedHabit(
      id: 99,
      habit: Habit.vaping,
      createdAt: DateTime(2026, 10, 16),
    );

    expect(
      (await repository.update(missing) as FailureResult<void>).failure,
      isA<NotFoundFailure>(),
    );
    expect(
      (await repository.archive(
        99,
        at: DateTime(2026, 10, 16),
      ) as FailureResult<void>).failure,
      isA<NotFoundFailure>(),
    );
  });
}

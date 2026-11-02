import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
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

  group('setPrice', () {
    final nov2 = LogicalDay(2026, 11, 2);
    final nov3 = LogicalDay(2026, 11, 3);
    late TrackedHabit habit;

    setUp(
      () async =>
          habit = await add(Habit.vaping, createdAt: DateTime(2026, 11)),
    );

    Future<Result<void>> setPrice(
      LogicalDay day,
      int? cents, {
      int units = 20,
      int? habitId,
    }) => repository.setPrice(
      habitId ?? habit.id,
      day: day,
      priceCents: cents,
      unitsPerContainer: units,
    );

    Future<List<(LogicalDay, int?, int)>> points() async => [
      for (final point in await repository.watchPrices(habit.id).first)
        (point.fromDay, point.priceCents, point.unitsPerContainer),
    ];

    test('updates the habit and writes a point', () async {
      expect(await setPrice(nov2, 900, units: 30), isA<Success<void>>());

      final [stored] = await getActive();
      expect(stored.priceCents, 900);
      expect(stored.unitsPerContainer, 30);
      expect(await points(), [(nov2, 900, 30)]);
    });

    test('a missing habit fails with NotFound and writes no point', () async {
      final result = await setPrice(nov2, 900, habitId: 99);

      expect((result as FailureResult<void>).failure, isA<NotFoundFailure>());
      expect(await database.select(database.habitPrices).get(), isEmpty);
    });

    test('a second change on the same day replaces its point', () async {
      await setPrice(nov2, 900);
      await setPrice(nov2, 950, units: 25);

      expect(await points(), [(nov2, 950, 25)]);
    });

    test('a change on a later day adds a point', () async {
      await setPrice(nov2, 900);
      await setPrice(nov3, 950);

      expect(await points(), [(nov2, 900, 20), (nov3, 950, 20)]);
    });

    test('no price and no points: no point', () async {
      await setPrice(nov2, null);

      expect(await points(), isEmpty);
    });

    test('an unchanged price writes no point', () async {
      await setPrice(nov2, 900);
      await setPrice(nov3, 900);

      expect(await points(), [(nov2, 900, 20)]);
    });

    test('a units change alone writes a point', () async {
      await setPrice(nov2, 900);
      await setPrice(nov3, 900, units: 30);

      expect(await points(), [(nov2, 900, 20), (nov3, 900, 30)]);
    });

    test('a first price cleared the same day leaves no point', () async {
      await setPrice(nov2, 900);
      await setPrice(nov2, null);

      expect((await getActive()).single.priceCents, isNull);
      expect(await points(), isEmpty);

      await setPrice(nov3, 950);
      expect(await points(), [(nov3, 950, 20)]);
    });

    test('clearing on a later day writes a point with no price', () async {
      await setPrice(nov2, 900);
      await setPrice(nov3, null);

      expect(await points(), [(nov2, 900, 20), (nov3, null, 20)]);
    });

    test('clearing the same day keeps the earlier point', () async {
      await setPrice(nov2, 900);
      await setPrice(nov3, 950);
      await setPrice(nov3, null);

      expect(await points(), [(nov2, 900, 20), (nov3, null, 20)]);
    });

    test('clearing twice writes one point with no price', () async {
      await setPrice(nov2, 900);
      await setPrice(nov3, null);
      await setPrice(nov3.addDays(1), null);

      expect(await points(), [(nov2, 900, 20), (nov3, null, 20)]);
    });

    test('points are kept per habit', () async {
      final other = await add(Habit.caffeine, createdAt: DateTime(2026, 11));
      await setPrice(nov2, 900);
      await setPrice(nov2, 300, habitId: other.id);

      expect(await points(), [(nov2, 900, 20)]);
    });
  });
}

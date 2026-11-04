import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/habit/data/datasources/habit_local_data_source.dart';
import 'package:exhale/features/habit/data/repositories/local_habit_repository.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/domain/entities/habit_draft.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:exhale/features/habit/domain/usecases/set_habit_price.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late LocalHabitRepository repository;
  late SetHabitPrice setHabitPrice;
  late int habitId;
  final day = LogicalDay(2026, 11, 2);

  setUp(() async {
    database = createTestDatabase();
    repository = LocalHabitRepository(HabitLocalDataSource(database));
    setHabitPrice = SetHabitPrice(repository);
    habitId = (await repository.add(
      const HabitDraft(habit: Habit.vaping),
      createdAt: DateTime(2026, 11),
    ) as Success<TrackedHabit>).value.id;
  });

  tearDown(() => database.close());

  test('stores the price on the habit and as a point', () async {
    final result = await setHabitPrice((
      habitId: habitId,
      day: day,
      priceCents: 900,
      unitsPerContainer: 30,
    ));

    expect(result, isA<Success<void>>());
    final [habit] =
        (await repository.getActive() as Success<List<TrackedHabit>>).value;
    expect(habit.priceCents, 900);
    expect(habit.unitsPerContainer, 30);
    final [point] = await repository.watchPrices(habitId).first;
    expect(point.fromDay, day);
    expect(point.priceCents, 900);
    expect(point.unitsPerContainer, 30);
  });

  test('rejects an out-of-range price or container size', () async {
    const invalid = [(-1, 20), (100001, 20), (900, 0), (900, 101)];
    for (final (cents, units) in invalid) {
      final result = await setHabitPrice((
        habitId: habitId,
        day: day,
        priceCents: cents,
        unitsPerContainer: units,
      ));
      expect(
        (result as FailureResult<void>).failure,
        isA<ValidationFailure>(),
        reason: '$cents per $units',
      );
    }
    expect(await repository.watchPrices(habitId).first, isEmpty);
  });
}

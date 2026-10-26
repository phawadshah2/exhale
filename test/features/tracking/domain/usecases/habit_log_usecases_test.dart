import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/features/tracking/data/datasources/habit_log_local_data_source.dart';
import 'package:exhale/features/tracking/data/repositories/local_habit_log_repository.dart';
import 'package:exhale/features/tracking/domain/entities/habit_log.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:exhale/features/tracking/domain/usecases/add_habit_log.dart';
import 'package:exhale/features/tracking/domain/usecases/delete_habit_log.dart';
import 'package:exhale/features/tracking/domain/usecases/update_habit_log.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fixed_clock.dart';
import '../../../../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late LocalHabitLogRepository repository;
  late FixedClock clock;

  final now = DateTime(2026, 10, 16, 15, 42);

  setUp(() async {
    database = createTestDatabase();
    repository = LocalHabitLogRepository(HabitLogLocalDataSource(database));
    clock = FixedClock(now);
    await insertTestHabit(database);
  });

  tearDown(() => database.close());

  group('AddHabitLog', () {
    test('logs at the current time by default', () async {
      final result = await AddHabitLog(repository, clock)(
        const AddHabitLogInput(habitId: 1, trigger: Trigger.coffee),
      );

      final log = (result as Success<HabitLog>).value;
      expect(log.loggedAt, now);
      expect(log.habitId, 1);
      expect(log.trigger, Trigger.coffee);
    });

    test('back-fills a missed log and trims the note', () async {
      final earlier = now.subtract(const Duration(hours: 3));

      final result = await AddHabitLog(repository, clock)(
        AddHabitLogInput(
          habitId: 1,
          loggedAt: earlier,
          note: '  after lunch  ',
        ),
      );

      final log = (result as Success<HabitLog>).value;
      expect(log.loggedAt, earlier);
      expect(log.note, 'after lunch');
    });

    test('stores a blank note as null', () async {
      final result = await AddHabitLog(repository, clock)(
        const AddHabitLogInput(habitId: 1, note: '   '),
      );

      expect((result as Success<HabitLog>).value.note, isNull);
    });

    test('rejects a future time', () async {
      final result = await AddHabitLog(repository, clock)(
        AddHabitLogInput(
          habitId: 1,
          loggedAt: now.add(const Duration(minutes: 1)),
        ),
      );

      expect(
        (result as FailureResult<HabitLog>).failure,
        isA<ValidationFailure>(),
      );
      expect(await repository.watchLatest(habitId: 1).first, isNull);
    });
  });

  group('UpdateHabitLog', () {
    test('rejects moving a log into the future', () async {
      final log = (await AddHabitLog(repository, clock)(
        const AddHabitLogInput(habitId: 1),
      ) as Success<HabitLog>).value;

      final result = await UpdateHabitLog(repository, clock)(
        log.copyWith(loggedAt: now.add(const Duration(hours: 1))),
      );

      expect((result as FailureResult<void>).failure, isA<ValidationFailure>());
    });

    test('saves an edit', () async {
      final log = (await AddHabitLog(repository, clock)(
        const AddHabitLogInput(habitId: 1),
      ) as Success<HabitLog>).value;
      final edited = log.copyWith(trigger: () => Trigger.habit);

      expect(
        await UpdateHabitLog(repository, clock)(edited),
        isA<Success<void>>(),
      );
      expect(await repository.watchLatest(habitId: 1).first, edited);
    });
  });

  test('DeleteHabitLog removes the log', () async {
    final log = (await AddHabitLog(repository, clock)(
      const AddHabitLogInput(habitId: 1),
    ) as Success<HabitLog>).value;

    expect(await DeleteHabitLog(repository)(log.id), isA<Success<void>>());
    expect(await repository.watchLatest(habitId: 1).first, isNull);
  });
}

import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/tracking/data/datasources/habit_log_local_data_source.dart';
import 'package:exhale/features/tracking/data/repositories/local_habit_log_repository.dart';
import 'package:exhale/features/tracking/domain/entities/habit_log.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late LocalHabitLogRepository repository;

  setUp(() {
    database = createTestDatabase();
    repository = LocalHabitLogRepository(HabitLogLocalDataSource(database));
  });

  tearDown(() => database.close());

  Future<HabitLog> add(
    DateTime at, {
    HabitKind habitKind = HabitKind.vaping,
    Trigger? trigger,
    String? note,
  }) async => (await repository.addLog(
    loggedAt: at,
    habitKind: habitKind,
    trigger: trigger,
    note: note,
  ) as Success<HabitLog>).value;

  test('adds a log and returns it with an id', () async {
    final log = await add(
      DateTime(2026, 10, 16, 8, 15),
      trigger: Trigger.coffee,
      note: 'Morning coffee',
    );

    expect(log.id, greaterThan(0));
    expect(log.loggedAt, DateTime(2026, 10, 16, 8, 15));
    expect(log.habitKind, HabitKind.vaping);
    expect(log.trigger, Trigger.coffee);
    expect(log.note, 'Morning coffee');
  });

  test('watchLogs returns the half-open range in time order', () async {
    final from = DateTime(2026, 10, 16, 4);
    final to = DateTime(2026, 10, 17, 4);

    await add(DateTime(2026, 10, 16, 3, 59));
    final atStart = await add(from);
    final late = await add(DateTime(2026, 10, 17, 1, 30));
    final morning = await add(DateTime(2026, 10, 16, 9));
    await add(to);

    final logs = await repository
        .watchLogs(habitKind: HabitKind.vaping, from: from, to: to)
        .first;

    expect(logs, [atStart, morning, late]);
  });

  test('watching one habit leaves out logs of another', () async {
    final vaping = await add(DateTime(2026, 10, 16, 9));
    await add(DateTime(2026, 10, 16, 10), habitKind: HabitKind.smoking);

    final logs = await repository
        .watchLogs(
          habitKind: HabitKind.vaping,
          from: DateTime(2026, 10, 16),
          to: DateTime(2026, 10, 17),
        )
        .first;

    expect(logs, [vaping]);
    expect(
      await repository.watchLatest(habitKind: HabitKind.vaping).first,
      vaping,
    );
  });

  test('watchLatest follows the most recent log time', () async {
    expect(
      await repository.watchLatest(habitKind: HabitKind.vaping).first,
      isNull,
    );

    final newest = await add(DateTime(2026, 10, 16, 12));
    await add(DateTime(2026, 10, 16, 9));

    expect(
      await repository.watchLatest(habitKind: HabitKind.vaping).first,
      newest,
    );
  });

  test('updates the time, trigger and note', () async {
    final log = await add(DateTime(2026, 10, 16, 9), trigger: Trigger.stress);
    final edited = log.copyWith(
      loggedAt: DateTime(2026, 10, 16, 9, 30),
      trigger: () => null,
      note: () => 'Walk',
    );

    expect(await repository.updateLog(edited), isA<Success<void>>());
    expect(
      await repository.watchLatest(habitKind: HabitKind.vaping).first,
      edited,
    );
  });

  test('deletes a log', () async {
    final log = await add(DateTime(2026, 10, 16, 9));

    expect(await repository.deleteLog(log.id), isA<Success<void>>());
    expect(
      await repository.watchLatest(habitKind: HabitKind.vaping).first,
      isNull,
    );
  });

  test('update and delete report a missing log', () async {
    final ghost = HabitLog(
      id: 999,
      loggedAt: DateTime(2026, 10, 16),
      habitKind: HabitKind.smoking,
    );

    expect(
      (await repository.updateLog(ghost) as FailureResult<void>).failure,
      isA<NotFoundFailure>(),
    );
    expect(
      (await repository.deleteLog(999) as FailureResult<void>).failure,
      isA<NotFoundFailure>(),
    );
  });

  test('a database error is reported as a storage failure', () async {
    await database.customStatement('DROP TABLE habit_logs');

    final result = await repository.addLog(
      loggedAt: DateTime(2026, 10, 16),
      habitKind: HabitKind.smoking,
    );

    expect((result as FailureResult<HabitLog>).failure, isA<StorageFailure>());
  });
}

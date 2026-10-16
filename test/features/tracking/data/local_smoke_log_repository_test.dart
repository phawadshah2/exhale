import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/features/tracking/data/datasources/smoke_log_local_data_source.dart';
import 'package:exhale/features/tracking/data/repositories/local_smoke_log_repository.dart';
import 'package:exhale/features/tracking/domain/entities/smoke_log.dart';
import 'package:exhale/features/tracking/domain/entities/smoke_trigger.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late LocalSmokeLogRepository repository;

  setUp(() {
    database = createTestDatabase();
    repository = LocalSmokeLogRepository(SmokeLogLocalDataSource(database));
  });

  tearDown(() => database.close());

  Future<SmokeLog> add(
    DateTime at, {
    SmokeTrigger? trigger,
    String? note,
  }) async => (await repository.addLog(
    loggedAt: at,
    trigger: trigger,
    note: note,
  ) as Success<SmokeLog>).value;

  test('adds a log and returns it with an id', () async {
    final log = await add(
      DateTime(2026, 10, 16, 8, 15),
      trigger: SmokeTrigger.coffee,
      note: 'Morning coffee',
    );

    expect(log.id, greaterThan(0));
    expect(log.loggedAt, DateTime(2026, 10, 16, 8, 15));
    expect(log.trigger, SmokeTrigger.coffee);
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

    final logs = await repository.watchLogs(from: from, to: to).first;

    expect(logs, [atStart, morning, late]);
  });

  test('watchLatest follows the most recent log time', () async {
    expect(await repository.watchLatest().first, isNull);

    final newest = await add(DateTime(2026, 10, 16, 12));
    await add(DateTime(2026, 10, 16, 9));

    expect(await repository.watchLatest().first, newest);
  });

  test('updates the time, trigger and note', () async {
    final log = await add(
      DateTime(2026, 10, 16, 9),
      trigger: SmokeTrigger.stress,
    );
    final edited = log.copyWith(
      loggedAt: DateTime(2026, 10, 16, 9, 30),
      trigger: () => null,
      note: () => 'Walk',
    );

    expect(await repository.updateLog(edited), isA<Success<void>>());
    expect(await repository.watchLatest().first, edited);
  });

  test('deletes a log', () async {
    final log = await add(DateTime(2026, 10, 16, 9));

    expect(await repository.deleteLog(log.id), isA<Success<void>>());
    expect(await repository.watchLatest().first, isNull);
  });

  test('update and delete report a missing log', () async {
    final ghost = SmokeLog(id: 999, loggedAt: DateTime(2026, 10, 16));

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
    await database.customStatement('DROP TABLE smoke_logs');

    final result = await repository.addLog(loggedAt: DateTime(2026, 10, 16));

    expect((result as FailureResult<SmokeLog>).failure, isA<StorageFailure>());
  });
}

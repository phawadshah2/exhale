import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/features/tracking/data/datasources/smoke_log_local_data_source.dart';
import 'package:exhale/features/tracking/data/repositories/local_smoke_log_repository.dart';
import 'package:exhale/features/tracking/domain/entities/smoke_log.dart';
import 'package:exhale/features/tracking/domain/entities/smoke_trigger.dart';
import 'package:exhale/features/tracking/domain/usecases/delete_smoke_log.dart';
import 'package:exhale/features/tracking/domain/usecases/log_smoke.dart';
import 'package:exhale/features/tracking/domain/usecases/update_smoke_log.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fixed_clock.dart';
import '../../../../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late LocalSmokeLogRepository repository;
  late FixedClock clock;

  final now = DateTime(2026, 10, 16, 15, 42);

  setUp(() {
    database = createTestDatabase();
    repository = LocalSmokeLogRepository(SmokeLogLocalDataSource(database));
    clock = FixedClock(now);
  });

  tearDown(() => database.close());

  group('LogSmoke', () {
    test('logs at the current time by default', () async {
      final result = await LogSmoke(repository, clock)(
        const LogSmokeInput(trigger: SmokeTrigger.coffee),
      );

      final log = (result as Success<SmokeLog>).value;
      expect(log.loggedAt, now);
      expect(log.trigger, SmokeTrigger.coffee);
    });

    test('back-fills a missed log and trims the note', () async {
      final earlier = now.subtract(const Duration(hours: 3));

      final result = await LogSmoke(repository, clock)(
        LogSmokeInput(loggedAt: earlier, note: '  after lunch  '),
      );

      final log = (result as Success<SmokeLog>).value;
      expect(log.loggedAt, earlier);
      expect(log.note, 'after lunch');
    });

    test('stores a blank note as null', () async {
      final result = await LogSmoke(repository, clock)(
        const LogSmokeInput(note: '   '),
      );

      expect((result as Success<SmokeLog>).value.note, isNull);
    });

    test('rejects a future time', () async {
      final result = await LogSmoke(repository, clock)(
        LogSmokeInput(loggedAt: now.add(const Duration(minutes: 1))),
      );

      expect(
        (result as FailureResult<SmokeLog>).failure,
        isA<ValidationFailure>(),
      );
      expect(await repository.watchLatest().first, isNull);
    });
  });

  group('UpdateSmokeLog', () {
    test('rejects moving a log into the future', () async {
      final log = (await LogSmoke(repository, clock)(
        const LogSmokeInput(),
      ) as Success<SmokeLog>).value;

      final result = await UpdateSmokeLog(repository, clock)(
        log.copyWith(loggedAt: now.add(const Duration(hours: 1))),
      );

      expect((result as FailureResult<void>).failure, isA<ValidationFailure>());
    });

    test('saves an edit', () async {
      final log = (await LogSmoke(repository, clock)(
        const LogSmokeInput(),
      ) as Success<SmokeLog>).value;
      final edited = log.copyWith(trigger: () => SmokeTrigger.habit);

      expect(
        await UpdateSmokeLog(repository, clock)(edited),
        isA<Success<void>>(),
      );
      expect(await repository.watchLatest().first, edited);
    });
  });

  test('DeleteSmokeLog removes the log', () async {
    final log = (await LogSmoke(repository, clock)(
      const LogSmokeInput(),
    ) as Success<SmokeLog>).value;

    expect(await DeleteSmokeLog(repository)(log.id), isA<Success<void>>());
    expect(await repository.watchLatest().first, isNull);
  });
}

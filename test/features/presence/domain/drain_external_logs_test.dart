import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/features/presence/domain/queued_log.dart';
import 'package:exhale/features/presence/domain/usecases/drain_external_logs.dart';
import 'package:exhale/features/tracking/data/datasources/habit_log_local_data_source.dart';
import 'package:exhale/features/tracking/data/repositories/local_habit_log_repository.dart';
import 'package:exhale/features/tracking/domain/entities/habit_log.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_presence_repository.dart';
import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late LocalHabitLogRepository logs;
  late FakePresenceRepository presence;
  late DrainExternalLogs drain;
  late int habitId;

  final first = QueuedLog(id: 'a', loggedAt: DateTime(2026, 11, 14, 8, 15));
  final second = QueuedLog(id: 'b', loggedAt: DateTime(2026, 11, 14, 9, 40));

  setUp(() async {
    database = createTestDatabase();
    habitId = await insertTestHabit(database);
    logs = LocalHabitLogRepository(HabitLogLocalDataSource(database));
    presence = FakePresenceRepository();
    drain = DrainExternalLogs(logs, presence);
  });

  tearDown(() => database.close());

  Future<List<HabitLog>> stored() async => (await logs.getLogs(
    from: DateTime(2026),
    to: DateTime(2027),
    habitId: habitId,
  ) as Success<List<HabitLog>>).value;

  test('inserts each queued log at its time with no trigger', () async {
    presence.queue.addAll([first, second]);

    final result = await drain(habitId);

    expect((result as Success<int>).value, 2);
    final saved = await stored();
    expect(saved.map((log) => log.loggedAt), [first.loggedAt, second.loggedAt]);
    expect(saved.map((log) => log.trigger), [null, null]);
    expect(saved.map((log) => log.note), [null, null]);
    expect(
      (await logs.storedExternalIds(['a', 'b']) as Success<Set<String>>).value,
      {'a', 'b'},
    );
    expect(presence.queue, isEmpty);
  });

  test('an empty queue inserts and removes nothing', () async {
    final result = await drain(habitId);

    expect((result as Success<int>).value, 0);
    expect(presence.removals, isEmpty);
  });

  test('drainingTwiceInsertsOnce', () async {
    presence.queue.add(first);
    await drain(habitId);
    // The removal is lost, as if the app was killed before it ran.
    presence.queue.add(first);

    final again = await drain(habitId);

    expect((again as Success<int>).value, 0);
    expect(await stored(), hasLength(1));
    expect(presence.queue, isEmpty);
  });

  test('aStoredIdIsRemovedNotReinserted', () async {
    await logs.addLog(
      habitId: habitId,
      loggedAt: first.loggedAt,
      externalId: first.id,
    );
    presence.queue.addAll([first, second]);

    final result = await drain(habitId);

    expect((result as Success<int>).value, 1);
    expect(await stored(), hasLength(2));
    expect(presence.removals.single, {'a', 'b'});
    expect(presence.queue, isEmpty);
  });

  test('a repeated id in the queue is inserted once', () async {
    presence.queue.addAll([first, first]);

    final result = await drain(habitId);

    expect((result as Success<int>).value, 1);
    expect(await stored(), hasLength(1));
  });

  test('removes exactly the drained ids', () async {
    final late = QueuedLog(id: 'c', loggedAt: DateTime(2026, 11, 14, 10));
    presence
      ..queue.add(first)
      ..afterRead = () => presence.queue.add(late);

    await drain(habitId);

    expect(presence.removals.single, {'a'});
    expect(presence.queue, [late]);
  });

  test('a failed insert removes nothing', () async {
    presence.queue.add(first);

    final result = await drain(habitId + 1);

    expect(result, isA<FailureResult<int>>());
    expect(presence.removals, isEmpty);
    expect(presence.queue, [first]);
  });
}

import 'dart:convert';

import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/presence/data/presence_channel_repository.dart';
import 'package:exhale/features/presence/domain/activity_content.dart';
import 'package:exhale/features/presence/domain/presence_snapshot.dart';
import 'package:exhale/features/presence/domain/queued_log.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

PresenceSnapshot snapshotFor(LogicalDay today) => PresenceSnapshot.build(
  now: DateTime(2026, 11, 14, 10),
  today: today,
  settings: const AppSettings(),
  habit: TrackedHabit(
    id: 1,
    habit: Habit.vaping,
    createdAt: DateTime(2026, 11),
  ),
  history: PlanHistory([
    ReductionPlan(
      startDay: LogicalDay(2026, 11, 1),
      startLimit: 9,
      quitDay: LogicalDay(2027, 1, 3),
    ),
  ]),
  counts: {today: 2},
  todayLogs: [DateTime(2026, 11, 14, 8)],
  entitled: true,
  lastPair: (counting: 'Slow is still forward.', waiting: 'Progress.'),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('exhale/presence');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;
  late Object? Function(MethodCall call) reply;
  late PresenceChannelRepository repository;

  setUp(() {
    calls = [];
    reply = (_) => null;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return reply(call);
    });
    repository = PresenceChannelRepository(channel);
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('writeSnapshot sends the JSON string', () async {
    final snapshot = snapshotFor(LogicalDay(2026, 11, 14));

    final result = await repository.writeSnapshot(snapshot);

    expect(result, isA<Success<void>>());
    expect(calls.single.method, 'writeSnapshot');
    expect(jsonDecode(calls.single.arguments as String), snapshot.toJson());
  });

  test('readQueue parses the JSON string', () async {
    reply = (_) => jsonEncode([
      {'id': 'a', 'loggedAt': '2026-11-14T08:15:00.000Z'},
      {'id': 'b', 'loggedAt': '2026-11-14T09:40:30.000Z'},
    ]);

    final result = await repository.readQueue();

    expect(calls.single.method, 'readQueue');
    expect((result as Success<List<QueuedLog>>).value, [
      QueuedLog(id: 'a', loggedAt: DateTime.utc(2026, 11, 14, 8, 15).toLocal()),
      QueuedLog(
        id: 'b',
        loggedAt: DateTime.utc(2026, 11, 14, 9, 40, 30).toLocal(),
      ),
    ]);
  });

  test('a missing queue reads as empty', () async {
    final result = await repository.readQueue();

    expect((result as Success<List<QueuedLog>>).value, isEmpty);
  });

  test('removeFromQueue sends the ids', () async {
    await repository.removeFromQueue({'a', 'b'});

    expect(calls.single.method, 'removeFromQueue');
    expect(calls.single.arguments, unorderedEquals(['a', 'b']));
  });

  test('showActivity sends the content as JSON', () async {
    final content = ActivityContent(
      next: DateTime.utc(2026, 11, 14, 11),
      gap: const Duration(minutes: 90),
      count: 3,
      limit: 7,
      daysToGo: 40,
      countingLine: 'Slow is still forward.',
      waitingLine: 'Progress, not perfection.',
    );

    await repository.showActivity(content);

    expect(calls.single.method, 'showActivity');
    expect(jsonDecode(calls.single.arguments as String), {
      'next': '2026-11-14T11:00:00.000Z',
      'gapSeconds': 5400,
      'count': 3,
      'limit': 7,
      'daysToGo': 40,
      'countingLine': 'Slow is still forward.',
      'waitingLine': 'Progress, not perfection.',
      'staleAt': '2026-11-14T11:15:00.000Z',
    });
  });

  test('endActivity calls endActivity', () async {
    await repository.endActivity();

    expect(calls.single.method, 'endActivity');
  });

  test('a platform error is a failure', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => throw PlatformException(code: 'io'),
    );

    expect(await repository.endActivity(), isA<FailureResult<void>>());
    expect(await repository.readQueue(), isA<FailureResult<List<QueuedLog>>>());
  });

  test('queueChanged fires when Swift calls queueChanged', () async {
    final fired = expectLater(repository.queueChanged, emits(null));

    await messenger.handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(const MethodCall('queueChanged')),
      (_) {},
    );

    await fired;
  });
}

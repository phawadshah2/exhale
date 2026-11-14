import 'package:exhale/app/bootstrap.dart';
import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/providers/clock_providers.dart';
import 'package:exhale/features/paywall/data/fake/fake_store_repository.dart';
import 'package:exhale/features/paywall/domain/entities/access.dart';
import 'package:exhale/features/paywall/domain/entities/plan_kind.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/domain/repositories/plan_repository.dart';
import 'package:exhale/features/presence/domain/presence_snapshot.dart';
import 'package:exhale/features/presence/domain/queued_log.dart';
import 'package:exhale/features/presence/presentation/presence_sync.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/repositories/settings_repository.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/tracking/domain/repositories/habit_log_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_presence_repository.dart';
import '../../../helpers/fixed_clock.dart';
import '../../../helpers/pump_app.dart';

void main() {
  final today = LogicalDay(2026, 11, 14);
  late FixedClock clock;
  late FakePresenceRepository presence;
  late FakeStoreRepository store;
  late ProviderContainer container;
  late int habitId;

  setUp(() async {
    clock = FixedClock(DateTime(2026, 11, 14, 9));
    presence = FakePresenceRepository();
    store = FakeStoreRepository.entitled();
    await setUpTestDependencies(clock, store: store, presence: presence);
    final settings = sl<SettingsRepository>();
    final current = (await settings.get() as Success<AppSettings>).value;
    await settings.save(
      current.copyWith(wakeMinute: () => 7 * 60, bedMinute: () => 23 * 60),
    );
    habitId = await seedHabit(
      PlanDraft(
        startDay: LogicalDay(2026, 11, 1),
        startLimit: 8,
        quitDay: LogicalDay(2027, 1, 1),
      ),
    );
    container = ProviderContainer(overrides: await startupOverrides());
    addTearDown(container.listen(presenceSyncProvider, (_, _) {}).close);
  });

  tearDown(() async {
    container.dispose();
    await InjectionContainer.reset();
  });

  PresenceSync sync() => container.read(presenceSyncProvider);

  Future<void> settle() async {
    for (var i = 0; i < 3; i++) {
      await pumpEventQueue();
      await sync().idle;
    }
  }

  Future<void> start() async {
    sync();
    await settle();
  }

  Future<void> log([DateTime? at]) async {
    await sl<HabitLogRepository>().addLog(
      habitId: habitId,
      loggedAt: at ?? clock.now(),
    );
    await settle();
  }

  Future<int> limitToday() async => ((await sl<PlanRepository>().getHistory(
    habitId,
  )) as Success<PlanHistory?>).value!.limitOn(today);

  int? countOn(PresenceSnapshot snapshot, LogicalDay day) =>
      (snapshot.toJson()['days']! as List)
              .cast<Map<String, Object?>>()
              .singleWhere((d) => d['day'] == day.toString())['count']
          as int?;

  test('startup drains then writes a snapshot', () async {
    presence.queue.add(
      QueuedLog(id: 'q1', loggedAt: DateTime(2026, 11, 14, 8, 30)),
    );

    await start();

    expect(presence.queue, isEmpty);
    expect(presence.snapshots, isNotEmpty);
    expect(countOn(presence.snapshots.first, today), 1);
  });

  test(
    'a log writes a snapshot and shows the activity with a new line pair',
    () async {
      await start();
      final written = presence.snapshots.length;

      await log();
      expect(presence.snapshots.length, greaterThan(written));
      expect(presence.activities, hasLength(1));
      final first = presence.activities.single;
      expect(first.count, 1);
      expect(first.limit, await limitToday());

      clock.current = DateTime(2026, 11, 14, 9, 30);
      await log();

      expect(presence.activities, hasLength(2));
      final second = presence.activities.last;
      expect(second.count, 2);
      expect(second.countingLine, isNot(first.countingLine));
      expect(second.countingLine, isNot(first.waitingLine));
      final lastPair = presence.snapshots.last.toJson()['lastPair'];
      expect(lastPair, {
        'counting': second.countingLine,
        'waiting': second.waitingLine,
      });
    },
  );

  test('the first log of the day starts it, none before', () async {
    await start();
    expect(presence.activities, isEmpty);

    await log();

    expect(presence.activities, hasLength(1));
  });

  test('at the limit ends it', () async {
    await start();
    final limit = await limitToday();
    for (var i = 0; i < limit - 1; i++) {
      clock.current = clock.current.add(const Duration(minutes: 1));
      await log();
    }
    expect(presence.activities, isNotEmpty);
    final ended = presence.endedActivities;

    clock.current = clock.current.add(const Duration(minutes: 1));
    await log();

    expect(presence.endedActivities, ended + 1);
  });

  test('the switch off ends it and never shows it', () async {
    await start();
    await log();
    expect(presence.activities, hasLength(1));
    final ended = presence.endedActivities;

    await container
        .read(settingsActionsProvider)
        .update((s) => s.copyWith(showLiveActivity: false));
    await settle();
    expect(presence.endedActivities, ended + 1);
    expect(presence.snapshots.last.toJson()['showLiveActivity'], isFalse);

    clock.current = DateTime(2026, 11, 14, 10);
    await log();
    expect(presence.activities, hasLength(1));
  });

  test('losingAccessEndsActivityAndLocksSnapshot', () async {
    await start();
    await log();
    final ended = presence.endedActivities;

    store
      ..access = Lapsed(plan: PlanKind.annual, endedAt: clock.now())
      ..emitChange();
    await settle();

    expect(presence.snapshots.last.toJson()['entitled'], isFalse);
    expect(presence.endedActivities, ended + 1);
  });

  test('queueChangeWhileOpenDrainsThenWritesSnapshot', () async {
    await start();
    final written = presence.snapshots.length;

    presence.enqueue(QueuedLog(id: 'q2', loggedAt: clock.now()));
    await settle();

    expect(presence.queue, isEmpty);
    expect(presence.snapshots.length, greaterThan(written));
    // The first snapshot after the signal already holds the log.
    expect(countOn(presence.snapshots[written], today), 1);
    expect(presence.activities.single.count, 1);
  });

  test('resume past staleAt ends it', () async {
    await start();
    await log();
    final shown = presence.activities.single;
    final ended = presence.endedActivities;

    clock.current = shown.staleAt.add(const Duration(minutes: 1));
    await sync().resume();
    await settle();

    expect(presence.endedActivities, ended + 1);
  });

  test('resume before staleAt keeps it', () async {
    await start();
    await log();
    final ended = presence.endedActivities;

    clock.current = clock.current.add(const Duration(minutes: 5));
    await sync().resume();
    await settle();

    expect(presence.endedActivities, ended);
    expect(presence.activities, hasLength(1));
  });

  test('the day reset ends it and writes a snapshot', () async {
    await start();
    await log();
    final ended = presence.endedActivities;
    final written = presence.snapshots.length;

    clock.current = DateTime(2026, 11, 15, 5);
    container.invalidate(nowProvider);
    await settle();

    expect(presence.endedActivities, ended + 1);
    expect(presence.snapshots.length, greaterThan(written));
    final days = (presence.snapshots.last.toJson()['days']! as List)
        .cast<Map<String, Object?>>();
    expect(days[PresenceSnapshot.daysEachSide]['day'], '2026-11-15');
  });
}

import 'dart:convert';

import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/domain/entities/plan_hold.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/presence/domain/encouragement.dart';
import 'package:exhale/features/presence/domain/presence_snapshot.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

final today = LogicalDay(2026, 11, 14);
final now = DateTime(2026, 11, 14, 10, 30);
final plan = ReductionPlan(
  startDay: LogicalDay(2026, 11, 1),
  startLimit: 9,
  quitDay: LogicalDay(2027, 1, 3),
);
final tracked = TrackedHabit(
  id: 1,
  habit: Habit.vaping,
  createdAt: DateTime(2026, 11),
  reason: 'More breath on the stairs.',
);
const LinePair pair = (
  counting: 'Slow is still forward.',
  waiting: 'Progress.',
);

const settings = AppSettings(
  wakeMinute: 450,
  bedMinute: 1410,
  showLiveActivity: false,
);

PresenceSnapshot build({
  AppSettings settings = settings,
  PlanHistory? history,
  Map<LogicalDay, int> counts = const {},
  List<DateTime> todayLogs = const [],
  bool entitled = true,
}) => PresenceSnapshot.build(
  now: now,
  today: today,
  settings: settings,
  habit: tracked,
  history: history ?? PlanHistory([plan]),
  counts: counts,
  todayLogs: todayLogs,
  entitled: entitled,
  lastPair: pair,
);

List<Map<String, Object?>> daysOf(Map<String, Object?> json) =>
    (json['days']! as List).cast<Map<String, Object?>>();

Map<String, Object?> dayOf(Map<String, Object?> json, LogicalDay day) =>
    daysOf(json).singleWhere((d) => d['day'] == day.toString());

void main() {
  test('covers 62 days each side of today', () {
    final days = daysOf(build().toJson());

    expect(days, hasLength(125));
    expect(days.first['day'], today.addDays(-62).toString());
    expect(days.last['day'], today.addDays(62).toString());
    expect(days[62]['day'], today.toString());
  });

  test('writes the header, day settings and habit', () {
    final json = build().toJson();

    expect(json['version'], 1);
    expect(json['writtenAt'], now.toUtc().toIso8601String());
    expect(json['entitled'], isTrue);
    expect(json['resetHour'], 4);
    expect(json['wakeMinute'], 450);
    expect(json['awakeMinutes'], 960);
    expect(json['habit'], {
      'name': 'Vaping',
      'kind': 'vaping',
      'reason': 'More breath on the stairs.',
      'freeDayTitle': 'Vape-free day',
    });
    expect(json['quitDay'], '2027-01-03');
    expect(json['showLiveActivity'], isFalse);
    expect(json['lines'], encouragementLines);
    expect(json['lastPair'], {
      'counting': 'Slow is still forward.',
      'waiting': 'Progress.',
    });
  });

  test("each day carries its limit, stage and the plan's stage count", () {
    final json = build().toJson();

    final first = dayOf(json, LogicalDay(2026, 11, 1));
    expect(first['limit'], 9);
    expect(first['stage'], 1);
    expect(first['stageCount'], plan.stageCount);

    final todayEntry = dayOf(json, today);
    expect(todayEntry['limit'], plan.limitOn(today));
    expect(todayEntry['stage'], plan.stageOn(today)!.number);

    final beforeStart = dayOf(json, LogicalDay(2026, 10, 20));
    expect(beforeStart['limit'], 9);
    expect(beforeStart['stage'], isNull);

    final afterQuit = dayOf(json, LogicalDay(2027, 1, 10));
    expect(afterQuit['limit'], 0);
    expect(afterQuit['stage'], isNull);
  });

  test("past days carry their own plan's limit", () {
    final first = ReductionPlan(
      startDay: LogicalDay(2026, 10, 1),
      startLimit: 20,
      quitDay: LogicalDay(2026, 12, 31),
    );
    final second = ReductionPlan(
      startDay: LogicalDay(2026, 11, 10),
      startLimit: 6,
      quitDay: LogicalDay(2027, 2, 1),
    );
    final json = build(history: PlanHistory([first, second])).toJson();

    final before = LogicalDay(2026, 11, 5);
    final after = LogicalDay(2026, 11, 12);
    expect(dayOf(json, before)['limit'], first.limitOn(before));
    expect(dayOf(json, before)['stageCount'], first.stageCount);
    expect(dayOf(json, after)['limit'], second.limitOn(after));
    expect(dayOf(json, after)['stageCount'], second.stageCount);
    expect(first.limitOn(after), isNot(second.limitOn(after)));
    expect(json['quitDay'], '2027-02-01');
  });

  test('a hold shifts later limits and the quit day', () {
    final held = ReductionPlan(
      startDay: plan.startDay,
      startLimit: plan.startLimit,
      quitDay: plan.agreedQuitDay,
      holds: [PlanHold(startDay: LogicalDay(2026, 11, 8))],
    );
    final json = build(history: PlanHistory([held])).toJson();

    final later = LogicalDay(2026, 12, 20);
    expect(dayOf(json, later)['limit'], held.limitOn(later));
    expect(held.limitOn(later), isNot(plan.limitOn(later)));
    expect(json['quitDay'], '2027-01-10');
  });

  test('counts only on past days and today', () {
    final json = build(
      counts: {today.addDays(-3): 5, today: 2, today.addDays(2): 9},
    ).toJson();

    expect(dayOf(json, today.addDays(-3))['count'], 5);
    expect(dayOf(json, today.addDays(-1))['count'], 0);
    expect(dayOf(json, today)['count'], 2);
    expect(dayOf(json, today.addDays(1)).containsKey('count'), isFalse);
    expect(dayOf(json, today.addDays(2)).containsKey('count'), isFalse);
  });

  test("writes today's log times in UTC", () {
    final logs = [DateTime(2026, 11, 14, 7, 5), DateTime(2026, 11, 14, 9)];
    final json = build(todayLogs: logs).toJson();

    expect(json['todayLogs'], [
      for (final log in logs) log.toUtc().toIso8601String(),
    ]);
  });

  test('no window writes null wake and awake', () {
    final json = build(settings: const AppSettings()).toJson();

    expect(json.containsKey('wakeMinute'), isTrue);
    expect(json['wakeMinute'], isNull);
    expect(json.containsKey('awakeMinutes'), isTrue);
    expect(json['awakeMinutes'], isNull);
  });

  test('no reason writes null reason', () {
    final json = PresenceSnapshot.build(
      now: now,
      today: today,
      settings: settings,
      habit: TrackedHabit(
        id: 1,
        habit: Habit.socialMedia,
        createdAt: DateTime(2026, 11),
      ),
      history: PlanHistory([plan]),
      counts: const {},
      todayLogs: const [],
      entitled: true,
      lastPair: pair,
    ).toJson();

    final habit = json['habit']! as Map<String, Object?>;
    expect(habit['reason'], isNull);
    expect(habit['freeDayTitle'], 'Zero day');
  });

  test('not entitled writes entitled false', () {
    expect(build(entitled: false).toJson()['entitled'], isFalse);
  });

  test('toJson round-trips through jsonDecode', () {
    final json = build(
      counts: {today: 3},
      todayLogs: [DateTime(2026, 11, 14, 8)],
    ).toJson();

    expect(jsonDecode(jsonEncode(json)), json);
  });
}

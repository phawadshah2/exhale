import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/logs/domain/day_rail.dart';
import 'package:exhale/features/settings/domain/entities/day_window.dart';
import 'package:exhale/features/tracking/domain/entities/habit_log.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:flutter_test/flutter_test.dart';

final _day = LogicalDay(2026, 10, 20);

/// 7:30 to 23:30.
const _window = DayWindow(wakeMinute: 450, bedMinute: 1410);

DateTime _at(int hour, int minute) => DateTime(2026, 10, 20, hour, minute);
DateTime _nextMorning(int hour, int minute) =>
    DateTime(2026, 10, 21, hour, minute);

var _ids = 0;
HabitLog _logAt(DateTime at, {Trigger? trigger}) =>
    HabitLog(id: ++_ids, habitId: 1, loggedAt: at, trigger: trigger);
HabitLog _log(int hour, int minute, {Trigger? trigger}) =>
    _logAt(_at(hour, minute), trigger: trigger);

List<RailEntry> _build(
  List<HabitLog> logs, {
  int? limit = 9,
  DayWindow? window = _window,
  bool isToday = false,
  DateTime? next,
  Trigger? filter,
}) => DayRail.build(
  logs: logs,
  limit: limit,
  window: window,
  day: _day,
  isToday: isToday,
  next: next,
  filter: filter,
);

Matcher _logRow(HabitLog log, {bool over = false}) => isA<RailLog>()
    .having((e) => e.log, 'log', log)
    .having((e) => e.over, 'over', over);

Matcher _gap(Duration gap, {bool longest = false}) => isA<RailGap>()
    .having((e) => e.gap, 'gap', gap)
    .having((e) => e.longest, 'longest', longest);

Matcher _reached(int limit) =>
    isA<RailLimitReached>().having((e) => e.limit, 'limit', limit);

final Matcher _wake = isA<RailWake>();
final Matcher _bed = isA<RailBed>();
final Matcher _thenNothing = isA<RailThenNothing>();
final Matcher _nothingYet = isA<RailNothingYet>();
final Matcher _nothingLogged = isA<RailNothingLogged>();

void main() {
  group('a past day', () {
    test('runs wake, logs and gaps, then nothing, bed', () {
      final a = _log(9, 0);
      final b = _log(9, 30);
      final c = _log(12, 0);

      expect(_build([a, b, c]), [
        _wake,
        _logRow(a),
        _gap(const Duration(minutes: 30)),
        _logRow(b),
        _gap(const Duration(hours: 2, minutes: 30), longest: true),
        _logRow(c),
        _thenNothing,
        _bed,
      ]);
    });

    test('with no logs is wake, nothing logged, bed', () {
      expect(_build([]), [_wake, _nothingLogged, _bed]);
    });

    test('wake and bed carry their times', () {
      final rail = _build([]);

      expect((rail.first as RailWake).at, _at(7, 30));
      expect((rail.last as RailBed).at, _at(23, 30));
    });

    test('a bed after midnight lands on the next calendar date', () {
      final rail = _build(
        [],
        window: const DayWindow(wakeMinute: 450, bedMinute: 60),
      );

      expect((rail.last as RailBed).at, _nextMorning(1, 0));
    });
  });

  group('placed by time', () {
    test('a log before waking sits above wake, its gap straight after', () {
      final early = _log(6, 50);
      final later = _log(9, 0);

      expect(_build([early, later]), [
        _logRow(early),
        _gap(const Duration(hours: 2, minutes: 10)),
        _wake,
        _logRow(later),
        _thenNothing,
        _bed,
      ]);
    });

    test('with only a log before waking, then nothing follows wake', () {
      final early = _log(6, 50);

      expect(_build([early]), [_logRow(early), _wake, _thenNothing, _bed]);
    });

    test('a log after midnight sits after bed', () {
      final late = _log(22, 0);
      final small = _logAt(_nextMorning(0, 40));

      expect(_build([late, small]), [
        _wake,
        _logRow(late),
        _gap(const Duration(hours: 2, minutes: 40)),
        _bed,
        _logRow(small),
        _thenNothing,
      ]);
    });

    test('a log after midnight sits before a later bed', () {
      final small = _logAt(_nextMorning(0, 40));

      expect(
        _build([
          small,
        ], window: const DayWindow(wakeMinute: 450, bedMinute: 60)),
        [_wake, _logRow(small), _thenNothing, _bed],
      );
    });

    test('a log at the minute of waking follows wake', () {
      final log = _log(7, 30);

      expect(_build([log]), [_wake, _logRow(log), _thenNothing, _bed]);
    });

    test('a log at the minute of bed comes before bed', () {
      final log = _log(23, 30);

      expect(_build([log]), [_wake, _logRow(log), _thenNothing, _bed]);
    });
  });

  group('the limit', () {
    test('reached sits just before the first over log', () {
      final a = _log(9, 0);
      final b = _log(10, 0);
      final c = _log(12, 0);

      expect(_build([a, b, c], limit: 2), [
        _wake,
        _logRow(a),
        _gap(const Duration(hours: 1)),
        _logRow(b),
        _gap(const Duration(hours: 2), longest: true),
        _reached(2),
        _logRow(c, over: true),
        _thenNothing,
        _bed,
      ]);
    });

    test('reached appears once, and every log past it is over', () {
      final a = _log(9, 0);
      final b = _log(10, 0);
      final c = _log(12, 0);

      expect(_build([a, b, c], limit: 1), [
        _wake,
        _logRow(a),
        _gap(const Duration(hours: 1)),
        _reached(1),
        _logRow(b, over: true),
        _gap(const Duration(hours: 2), longest: true),
        _logRow(c, over: true),
        _thenNothing,
        _bed,
      ]);
    });

    test('exactly at the limit nothing is over and no mark shows', () {
      final a = _log(9, 0);
      final b = _log(10, 0);

      expect(_build([a, b], limit: 2), [
        _wake,
        _logRow(a),
        _gap(const Duration(hours: 1)),
        _logRow(b),
        _thenNothing,
        _bed,
      ]);
    });

    test('limit 0 with one log: reached sits right before it', () {
      final log = _log(9, 0);

      expect(_build([log], limit: 0), [
        _wake,
        _reached(0),
        _logRow(log, over: true),
        _thenNothing,
        _bed,
      ]);
    });

    test('limit 0 with a log before waking: reached is first', () {
      final log = _log(6, 0);

      expect(_build([log], limit: 0), [
        _reached(0),
        _logRow(log, over: true),
        _wake,
        _thenNothing,
        _bed,
      ]);
    });

    test('limit 0 with no logs shows no mark', () {
      expect(_build([], limit: 0), [_wake, _nothingLogged, _bed]);
    });
  });

  group('the longest gap', () {
    test('one gap is not called longest', () {
      final a = _log(9, 0);
      final b = _log(11, 0);

      expect(_build([a, b]), contains(_gap(const Duration(hours: 2))));
    });

    test('a later gap can be the longest', () {
      final rail = _build([_log(9, 0), _log(10, 0), _log(13, 0)]);

      expect(rail.whereType<RailGap>().map((e) => e.longest), [false, true]);
    });

    test('the earliest wins a tie', () {
      final rail = _build([_log(9, 0), _log(10, 0), _log(11, 0), _log(12, 0)]);

      expect(rail.whereType<RailGap>().map((e) => e.longest), [
        true,
        false,
        false,
      ]);
    });
  });

  group('today', () {
    final next = _at(16, 54);

    Matcher nextAt(DateTime at) =>
        isA<RailNext>().having((e) => e.at, 'at', at);

    test('after the last log: next, nothing yet, bed', () {
      final log = _log(9, 0);

      expect(_build([log], isToday: true, next: next), [
        _wake,
        _logRow(log),
        nextAt(next),
        _nothingYet,
        _bed,
      ]);
    });

    test('no next hides next and keeps nothing yet', () {
      final log = _log(9, 0);

      expect(_build([log], isToday: true), [
        _wake,
        _logRow(log),
        _nothingYet,
        _bed,
      ]);
    });

    test('with no logs: wake, next, nothing yet, bed', () {
      expect(_build([], isToday: true, next: next), [
        _wake,
        nextAt(next),
        _nothingYet,
        _bed,
      ]);
    });

    test('after bed, next and nothing yet close the rail', () {
      final late = _logAt(_nextMorning(0, 40));
      final after = _nextMorning(2, 0);

      expect(_build([late], isToday: true, next: after), [
        _wake,
        _bed,
        _logRow(late),
        nextAt(after),
        _nothingYet,
      ]);
    });
  });

  group('before the plan', () {
    test('shows logs and gaps only', () {
      final a = _log(6, 50);
      final b = _log(9, 0);
      final c = _log(12, 0);

      expect(_build([a, b, c], limit: null), [
        _logRow(a),
        _gap(const Duration(hours: 2, minutes: 10)),
        _logRow(b),
        _gap(const Duration(hours: 3), longest: true),
        _logRow(c),
      ]);
    });

    test('with no logs is the one nothing logged row', () {
      expect(_build([], limit: null), [_nothingLogged]);
    });
  });

  group('with no day window', () {
    test('a past day has no wake or bed', () {
      final a = _log(9, 0);
      final b = _log(10, 0);

      expect(_build([a, b], window: null, limit: 1), [
        _logRow(a),
        _gap(const Duration(hours: 1)),
        _reached(1),
        _logRow(b, over: true),
        _thenNothing,
      ]);
      expect(_build([], window: null), [_nothingLogged]);
    });

    test('today has no wake or bed', () {
      final next = _at(16, 54);

      expect(_build([], window: null, isToday: true, next: next), [
        isA<RailNext>(),
        _nothingYet,
      ]);
    });

    test('limit 0 puts reached first', () {
      final log = _log(9, 0);

      expect(_build([log], window: null, limit: 0), [
        _reached(0),
        _logRow(log, over: true),
        _thenNothing,
      ]);
    });
  });

  group('with a filter', () {
    test('shows only matching logs, with no marks or gaps', () {
      final a = _log(9, 0, trigger: Trigger.stress);
      final b = _log(10, 0, trigger: Trigger.afterMeal);
      final c = _log(12, 0, trigger: Trigger.stress);

      expect(_build([a, b, c], filter: Trigger.stress), [
        _logRow(a),
        _logRow(c),
      ]);
    });

    test('over still counts the whole day', () {
      final a = _log(9, 0, trigger: Trigger.afterMeal);
      final b = _log(10, 0, trigger: Trigger.afterMeal);
      final c = _log(12, 0, trigger: Trigger.stress);

      expect(_build([a, b, c], limit: 2, filter: Trigger.stress), [
        _logRow(c, over: true),
      ]);
    });

    test('today shows no next', () {
      final log = _log(9, 0, trigger: Trigger.stress);

      expect(
        _build([log], isToday: true, next: _at(16, 54), filter: Trigger.stress),
        [_logRow(log)],
      );
    });

    test('no match gives an empty list', () {
      final log = _log(9, 0, trigger: Trigger.afterMeal);

      expect(_build([log], filter: Trigger.stress), isEmpty);
      expect(_build([], filter: Trigger.stress), isEmpty);
    });
  });
}

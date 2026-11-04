import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/logs/domain/logs_selection.dart';
import 'package:exhale/features/logs/presentation/logs_query.dart';
import 'package:exhale/features/tracking/domain/entities/period_range.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:flutter_test/flutter_test.dart';

/// A Wednesday. Its week is Nov 2 to Nov 8.
final _today = LogicalDay(2026, 11, 4);

LogicalDay _nov(int day) => LogicalDay(2026, 11, day);
LogicalDay _oct(int day) => LogicalDay(2026, 10, day);

final _thisWeek = PeriodRange(_nov(2), _nov(8));
final _lastWeek = PeriodRange(_oct(26), _nov(1));

LogsSelection _open(LogicalDay from, LogicalDay to, {Trigger? trigger}) =>
    LogsSelection.fromQuery(
      LogsQuery(from: from, to: to, trigger: trigger),
      today: _today,
    );

void _expectShows(
  LogsSelection selection, {
  required PeriodRange period,
  required LogicalDay selected,
}) {
  expect(selection.period, period);
  expect(selection.selected, selected);
}

void main() {
  group('fromQuery', () {
    test('no range opens this week on today', () {
      _expectShows(
        LogsSelection.fromQuery(const LogsQuery(), today: _today),
        period: _thisWeek,
        selected: _today,
      );
    });

    test('one day opens its week on that day', () {
      _expectShows(
        _open(_oct(28), _oct(28)),
        period: _lastWeek,
        selected: _oct(28),
      );
    });

    test('a past whole week opens on its last day', () {
      _expectShows(
        _open(_oct(26), _nov(1)),
        period: _lastWeek,
        selected: _nov(1),
      );
    });

    test('this whole week opens on today, not its last day', () {
      _expectShows(
        _open(_nov(2), _nov(8)),
        period: _thisWeek,
        selected: _today,
      );
    });

    test('a month range opens as that range, on its last day', () {
      final selection = _open(_oct(1), _oct(31));

      _expectShows(
        selection,
        period: PeriodRange(_oct(1), _oct(31)),
        selected: _oct(31),
      );
      expect(selection.isRange, isTrue);
    });

    test("History's All range opens as that range, ending today", () {
      final selection = _open(LogicalDay(2026, 8, 14), _today);

      _expectShows(
        selection,
        period: PeriodRange(LogicalDay(2026, 8, 14), _today),
        selected: _today,
      );
      expect(selection.isRange, isTrue);
    });

    test('a month that has only just begun is still a range', () {
      // Nov 1 is a Sunday, the day before this week starts.
      final selection = _open(_nov(1), LogicalDay(2026, 11, 30));

      _expectShows(
        selection,
        period: PeriodRange(_nov(1), _today),
        selected: _today,
      );
      expect(selection.isRange, isTrue);
    });

    test('a week or a day is not a range', () {
      expect(_open(_oct(26), _nov(1)).isRange, isFalse);
      expect(_open(_oct(28), _oct(28)).isRange, isFalse);
    });

    test('picking a day leaves a range for its week', () {
      final picked = _open(_oct(1), _oct(31)).select(_oct(14));

      expect(picked.isRange, isFalse);
      expect(picked.period, PeriodRange(_oct(12), _oct(18)));
    });

    test('a range ending after today never opens on a future day', () {
      _expectShows(
        _open(_nov(20), _nov(20)),
        period: _thisWeek,
        selected: _today,
      );
      _expectShows(
        _open(LogicalDay(2026, 12, 1), LogicalDay(2026, 12, 31)),
        period: _thisWeek,
        selected: _today,
      );
    });

    test('a trigger is kept, and none stays none', () {
      expect(
        _open(_oct(28), _oct(28), trigger: Trigger.stress).trigger,
        Trigger.stress,
      );
      expect(_open(_oct(28), _oct(28)).trigger, isNull);
    });
  });

  group('step', () {
    test('an earlier week selects its last day', () {
      _expectShows(
        _open(_today, _today).step(-1, today: _today),
        period: _lastWeek,
        selected: _nov(1),
      );
    });

    test('a later week holding today selects today', () {
      _expectShows(
        _open(_oct(28), _oct(28)).step(1, today: _today),
        period: _thisWeek,
        selected: _today,
      );
    });

    test('a step past the week holding today stops there', () {
      _expectShows(
        _open(_today, _today).step(1, today: _today),
        period: _thisWeek,
        selected: _today,
      );
    });

    test('keeps the trigger', () {
      expect(
        _open(
          _today,
          _today,
          trigger: Trigger.stress,
        ).step(-1, today: _today).trigger,
        Trigger.stress,
      );
    });
  });

  group('select', () {
    test('a day in the shown week keeps the week', () {
      _expectShows(
        _open(_today, _today).select(_nov(3)),
        period: _thisWeek,
        selected: _nov(3),
      );
    });

    test('a day in another month jumps to its week and selects it', () {
      _expectShows(
        _open(_today, _today).select(LogicalDay(2026, 9, 2)),
        period: PeriodRange(LogicalDay(2026, 8, 31), LogicalDay(2026, 9, 6)),
        selected: LogicalDay(2026, 9, 2),
      );
    });

    test('clears the trigger', () {
      expect(
        _open(_today, _today, trigger: Trigger.stress).select(_nov(3)).trigger,
        isNull,
      );
    });
  });

  group('toggleTrigger', () {
    test('sets, replaces and clears', () {
      final on = _open(_today, _today).toggleTrigger(Trigger.stress);
      expect(on.trigger, Trigger.stress);

      final replaced = on.toggleTrigger(Trigger.afterMeal);
      expect(replaced.trigger, Trigger.afterMeal);

      expect(replaced.toggleTrigger(Trigger.afterMeal).trigger, isNull);
    });

    test('leaves the period and the day alone', () {
      _expectShows(
        _open(_oct(28), _oct(28)).toggleTrigger(Trigger.stress),
        period: _lastWeek,
        selected: _oct(28),
      );
    });
  });

  group('limits', () {
    test('the earlier arrow stops at the week holding earliest', () {
      final selection = _open(_oct(28), _oct(28));

      expect(selection.canGoEarlier(_oct(25)), isTrue);
      expect(selection.canGoEarlier(_oct(26)), isFalse);
      expect(selection.canGoEarlier(_nov(1)), isFalse);
    });

    test('the later arrow stops at the week holding today', () {
      expect(_open(_oct(28), _oct(28)).canGoLater(_today), isTrue);
      expect(_open(_oct(28), _oct(28)).canGoLater(_nov(1)), isFalse);
      expect(_open(_today, _today).canGoLater(_today), isFalse);
    });
  });

  group('left open past the reset hour', () {
    test('selected stays, and later opens once today is a new week', () {
      final sunday = _nov(1);
      final opened = LogsSelection.fromQuery(const LogsQuery(), today: sunday);
      expect(opened.canGoLater(sunday), isFalse);

      final monday = _nov(2);
      expect(opened.selected, sunday);
      expect(opened.period, _lastWeek);
      expect(opened.canGoLater(monday), isTrue);
      _expectShows(
        opened.step(1, today: monday),
        period: _thisWeek,
        selected: monday,
      );
    });

    test('later stays off while the new today is in the same week', () {
      final monday = _nov(2);
      final opened = LogsSelection.fromQuery(const LogsQuery(), today: monday);

      expect(opened.selected, monday);
      expect(opened.canGoLater(_nov(3)), isFalse);
    });
  });
}

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
final _thisMonth = PeriodRange(_nov(1), _nov(30));
final _october = PeriodRange(_oct(1), _oct(31));

LogsSelection _open(LogicalDay from, LogicalDay to, {Trigger? trigger}) =>
    LogsSelection.fromQuery(
      LogsQuery(from: from, to: to, trigger: trigger),
      today: _today,
    );

void _expectShows(
  LogsSelection selection, {
  required LogsMode mode,
  required PeriodRange period,
  required LogicalDay selected,
}) {
  expect(selection.mode, mode);
  expect(selection.period, period);
  expect(selection.selected, selected);
}

void main() {
  group('fromQuery', () {
    test('no range opens this week on today', () {
      _expectShows(
        LogsSelection.fromQuery(const LogsQuery(), today: _today),
        mode: LogsMode.week,
        period: _thisWeek,
        selected: _today,
      );
    });

    test('one day opens its week on that day', () {
      _expectShows(
        _open(_oct(28), _oct(28)),
        mode: LogsMode.week,
        period: _lastWeek,
        selected: _oct(28),
      );
    });

    test('a past whole week opens on its last day', () {
      _expectShows(
        _open(_oct(26), _nov(1)),
        mode: LogsMode.week,
        period: _lastWeek,
        selected: _nov(1),
      );
    });

    test('this whole week opens on today, not its last day', () {
      _expectShows(
        _open(_nov(2), _nov(8)),
        mode: LogsMode.week,
        period: _thisWeek,
        selected: _today,
      );
    });

    test('seven days that are not Monday to Sunday open as a month', () {
      _expectShows(
        _open(_oct(20), _oct(26)),
        mode: LogsMode.month,
        period: _october,
        selected: _oct(31),
      );
    });

    test('a past calendar month opens on its last day', () {
      _expectShows(
        _open(_oct(1), _oct(31)),
        mode: LogsMode.month,
        period: _october,
        selected: _oct(31),
      );
    });

    test('this calendar month opens on today', () {
      _expectShows(
        _open(_nov(1), _nov(30)),
        mode: LogsMode.month,
        period: _thisMonth,
        selected: _today,
      );
    });

    test("History's All range opens the month of its end", () {
      _expectShows(
        _open(LogicalDay(2026, 8, 14), _today),
        mode: LogsMode.month,
        period: _thisMonth,
        selected: _today,
      );
    });

    test('a range ending after today never opens on a future day', () {
      _expectShows(
        _open(_nov(20), _nov(20)),
        mode: LogsMode.week,
        period: _thisWeek,
        selected: _today,
      );
      _expectShows(
        _open(LogicalDay(2026, 12, 1), LogicalDay(2026, 12, 31)),
        mode: LogsMode.month,
        period: _thisMonth,
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
        mode: LogsMode.week,
        period: _lastWeek,
        selected: _nov(1),
      );
    });

    test('a later week holding today selects today', () {
      _expectShows(
        _open(_oct(28), _oct(28)).step(1, today: _today),
        mode: LogsMode.week,
        period: _thisWeek,
        selected: _today,
      );
    });

    test('a month step lands on whole months, from a 31-day month too', () {
      final october = _open(_oct(1), _oct(31));

      _expectShows(
        october.step(-1, today: _today),
        mode: LogsMode.month,
        period: PeriodRange(LogicalDay(2026, 9, 1), LogicalDay(2026, 9, 30)),
        selected: LogicalDay(2026, 9, 30),
      );
      _expectShows(
        october.step(1, today: _today),
        mode: LogsMode.month,
        period: _thisMonth,
        selected: _today,
      );
    });

    test('a month step crosses the year', () {
      _expectShows(
        _open(
          LogicalDay(2026, 1, 1),
          LogicalDay(2026, 1, 31),
        ).step(-1, today: _today),
        mode: LogsMode.month,
        period: PeriodRange(LogicalDay(2025, 12, 1), LogicalDay(2025, 12, 31)),
        selected: LogicalDay(2025, 12, 31),
      );
    });

    test('a step past the period holding today stops there', () {
      _expectShows(
        _open(_today, _today).step(1, today: _today),
        mode: LogsMode.week,
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

  group('withMode', () {
    test('Month keeps the selected day and shows its month', () {
      _expectShows(
        _open(_oct(28), _oct(28)).withMode(LogsMode.month),
        mode: LogsMode.month,
        period: _october,
        selected: _oct(28),
      );
    });

    test('Week keeps the selected day and shows its week', () {
      _expectShows(
        _open(_oct(1), _oct(31)).select(_oct(28)).withMode(LogsMode.week),
        mode: LogsMode.week,
        period: _lastWeek,
        selected: _oct(28),
      );
    });

    test('a week across two months shows the selected day month', () {
      _expectShows(
        _open(_nov(1), _nov(1)).withMode(LogsMode.month),
        mode: LogsMode.month,
        period: _thisMonth,
        selected: _nov(1),
      );
    });

    test('keeps the trigger', () {
      expect(
        _open(
          _today,
          _today,
          trigger: Trigger.stress,
        ).withMode(LogsMode.month).trigger,
        Trigger.stress,
      );
    });
  });

  group('pickMonth', () {
    test('switches to Month and selects the last day of a past month', () {
      _expectShows(
        _open(_today, _today).pickMonth(_oct(9), today: _today),
        mode: LogsMode.month,
        period: _october,
        selected: _oct(31),
      );
    });

    test('this month selects today', () {
      _expectShows(
        _open(_oct(1), _oct(31)).pickMonth(_nov(30), today: _today),
        mode: LogsMode.month,
        period: _thisMonth,
        selected: _today,
      );
    });

    test('keeps the trigger', () {
      expect(
        _open(
          _today,
          _today,
          trigger: Trigger.stress,
        ).pickMonth(_oct(9), today: _today).trigger,
        Trigger.stress,
      );
    });
  });

  group('select', () {
    test('changes the day and keeps the shown period', () {
      _expectShows(
        _open(_oct(1), _oct(31)).select(_oct(3)),
        mode: LogsMode.month,
        period: _october,
        selected: _oct(3),
      );
    });

    test('a day outside the period shows the period holding it', () {
      _expectShows(
        _open(_today, _today).select(_oct(28)),
        mode: LogsMode.week,
        period: _lastWeek,
        selected: _oct(28),
      );
    });

    test('keeps the trigger', () {
      expect(
        _open(_today, _today, trigger: Trigger.stress).select(_nov(3)).trigger,
        Trigger.stress,
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
        mode: LogsMode.week,
        period: _lastWeek,
        selected: _oct(28),
      );
    });
  });

  group('limits', () {
    test('the earlier arrow stops at the period holding earliest', () {
      final selection = _open(_oct(28), _oct(28));

      expect(selection.canGoEarlier(_oct(25)), isTrue);
      expect(selection.canGoEarlier(_oct(26)), isFalse);
      expect(selection.canGoEarlier(_nov(1)), isFalse);
    });

    test('the earlier arrow in Month stops at the month holding earliest', () {
      final selection = _open(_oct(1), _oct(31));

      expect(selection.canGoEarlier(LogicalDay(2026, 9, 30)), isTrue);
      expect(selection.canGoEarlier(_oct(1)), isFalse);
      expect(selection.canGoEarlier(_oct(31)), isFalse);
    });

    test('the later arrow stops at the period holding today', () {
      expect(_open(_oct(28), _oct(28)).canGoLater(_today), isTrue);
      expect(_open(_oct(28), _oct(28)).canGoLater(_nov(1)), isFalse);
      expect(_open(_today, _today).canGoLater(_today), isFalse);
    });

    test('the later arrow in Month stops at the month holding today', () {
      expect(_open(_oct(1), _oct(31)).canGoLater(_today), isTrue);
      expect(_open(_nov(1), _nov(30)).canGoLater(_today), isFalse);
    });
  });

  group('left open past the reset hour', () {
    test('selected stays, and later opens once today is a new period', () {
      final sunday = _nov(1);
      final opened = LogsSelection.fromQuery(const LogsQuery(), today: sunday);
      expect(opened.canGoLater(sunday), isFalse);

      final monday = _nov(2);
      expect(opened.selected, sunday);
      expect(opened.period, _lastWeek);
      expect(opened.canGoLater(monday), isTrue);
      _expectShows(
        opened.step(1, today: monday),
        mode: LogsMode.week,
        period: _thisWeek,
        selected: monday,
      );
    });

    test('later stays off while the new today is in the same period', () {
      final monday = _nov(2);
      final opened = LogsSelection.fromQuery(const LogsQuery(), today: monday);

      expect(opened.selected, monday);
      expect(opened.canGoLater(_nov(3)), isFalse);
    });
  });
}

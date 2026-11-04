import 'package:exhale/core/domain/time/day_boundary.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/domain/entities/plan_hold.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/plan/domain/entities/stage_check.dart';
import 'package:exhale/features/plan/domain/services/stage_checks.dart';
import 'package:exhale/features/tracking/domain/entities/habit_log.dart';
import 'package:flutter_test/flutter_test.dart';

LogicalDay _oct(int day) => LogicalDay(2026, 10, day);
LogicalDay _nov(int day) => LogicalDay(2026, 11, day);
LogicalDay _jan(int day) => LogicalDay(2027, 1, day);

/// 12 a day from Oct 12, quit Jan 4: stage k runs seven days at 13 − k, so
/// stage 3 (10 a day) ends Nov 1 and stage 4 (9 a day) ends Nov 8.
final _weekly = ReductionPlan(
  startDay: _oct(12),
  startLimit: 12,
  quitDay: _jan(4),
);

/// 10 a day from Oct 12 over 70 days: stage k runs seven days at 11 − k, so
/// stage 2 (9 a day) ends Oct 25 and stage 3 (8 a day) ends Nov 1.
final _ten = ReductionPlan(
  startDay: _oct(12),
  startLimit: 10,
  quitDay: LogicalDay(2026, 12, 21),
);

/// 7 a day from Oct 12 over 14 days: a drop every two days.
final _short = ReductionPlan(
  startDay: _oct(12),
  startLimit: 7,
  quitDay: _oct(26),
);

List<HabitLog> _logs(Map<LogicalDay, int> perDay) {
  final logs = <HabitLog>[];
  perDay.forEach((day, count) {
    for (var i = 0; i < count; i++) {
      logs.add(
        HabitLog(
          id: logs.length + 1,
          habitId: 1,
          loggedAt: DateTime(day.year, day.month, day.day, 12, i),
        ),
      );
    }
  });
  return logs;
}

/// [count] a day on each of the [days] days ending on [last].
Map<LogicalDay, int> _every(LogicalDay last, int days, int count) => {
  for (var i = 0; i < days; i++) last.addDays(-i): count,
};

/// Answered at noon on [answeredOn], by default the day of the check.
StageCheck _check(
  StageOutcome outcome,
  LogicalDay windowEnd, {
  LogicalDay? planStart,
  bool answered = true,
  LogicalDay? answeredOn,
}) {
  final checkDay = windowEnd.addDays(1);
  final on = answeredOn ?? checkDay;
  return StageCheck(
    planStartDay: planStart ?? _oct(12),
    windowEndDay: windowEnd,
    checkDay: checkDay,
    outcome: outcome,
    answeredAt: answered ? DateTime(on.year, on.month, on.day, 12) : null,
  );
}

StageCheckResult? _evaluate({
  required LogicalDay today,
  ReductionPlan? plan,
  Map<LogicalDay, int> logs = const {},
  List<StageCheck> checks = const [],
}) => StageChecks.evaluate(
  history: PlanHistory([plan ?? _weekly]),
  logs: _logs(logs),
  boundary: const DayBoundary(),
  checks: checks,
  today: today,
);

/// Stage 4 of [_weekly], Nov 2 to 8, all at its limit of 9 except [over].
Map<LogicalDay, int> _stage4({Map<LogicalDay, int> over = const {}}) => {
  ..._every(_nov(8), 7, 9),
  ...over,
};

void main() {
  group('the window', () {
    test('one day over and the rest at the limit passes', () {
      final result = _evaluate(
        today: _nov(9),
        logs: _stage4(over: {_nov(4): 12}),
      )!;

      expect(result.outcome, StageOutcome.passed);
      expect(result.logged, 66);
      expect(result.allowed, 63);
      expect(result.overDays, 1);
      expect(result.windowEndDay, _nov(8));
    });

    test('two days over with the total over fails', () {
      final result = _evaluate(
        today: _nov(9),
        logs: _stage4(over: {_nov(3): 12, _nov(4): 12}),
      )!;

      expect(result.outcome, StageOutcome.hold);
      expect(result.logged, 69);
      expect(result.overDays, 2);
    });

    test('two days over with the total under passes', () {
      final result = _evaluate(
        today: _nov(9),
        logs: {_nov(3): 12, _nov(4): 12},
      )!;

      expect(result.outcome, StageOutcome.passed);
      expect(result.logged, 24);
      expect(result.overDays, 2);
    });

    test('logged equal to allowed passes', () {
      final result = _evaluate(
        today: _nov(9),
        logs: {
          _nov(2): 12,
          _nov(3): 12,
          _nov(4): 9,
          _nov(5): 9,
          _nov(6): 9,
          _nov(7): 6,
          _nov(8): 6,
        },
      )!;

      expect(result.logged, result.allowed);
      expect(result.overDays, 2);
      expect(result.outcome, StageOutcome.passed);
    });

    test("a window across short stages uses each day's limit", () {
      // Oct 15 to 21 allows 6 + 5 + 5 + 4 + 4 + 3 + 3.
      final result = _evaluate(
        today: _oct(22),
        plan: _short,
        logs: _every(_oct(21), 7, 5),
      )!;

      expect(result.windowEndDay, _oct(21));
      expect(result.allowed, 30);
      expect(result.logged, 35);
      expect(result.overDays, 4);
      expect(result.outcome, StageOutcome.hold);
    });

    test('a log before the reset hour belongs to the previous day', () {
      final result = StageChecks.evaluate(
        history: PlanHistory([_weekly]),
        logs: [
          for (var i = 0; i < 20; i++)
            HabitLog(id: i, habitId: 1, loggedAt: DateTime(2026, 11, 9, 1, i)),
        ],
        boundary: const DayBoundary(),
        checks: const [],
        today: _nov(9),
      )!;

      expect(result.logged, 20);
      expect(result.overDays, 1);
    });
  });

  group('when a check is due', () {
    test('not before the plan has run 7 days', () {
      // Stage 3 of the short plan ends Oct 17, after 6 days.
      expect(_evaluate(today: _oct(18), plan: _short), isNull);
    });

    test('on the seventh day of the plan', () {
      expect(_evaluate(today: _oct(19)), isNotNull);
    });

    test('not within 7 days of the last window', () {
      expect(
        _evaluate(
          today: _nov(9),
          checks: [_check(StageOutcome.passed, _nov(2))],
        ),
        isNull,
      );
    });

    test('exactly 7 days after the last window', () {
      expect(
        _evaluate(
          today: _nov(9),
          checks: [_check(StageOutcome.passed, _nov(1))],
        ),
        isNotNull,
      );
    });

    test('a window already checked is not due again', () {
      expect(
        _evaluate(
          today: _nov(9),
          checks: [_check(StageOutcome.passed, _nov(8))],
        ),
        isNull,
      );
    });

    test('only the latest ended stage is checked', () {
      // Stage 3 failed, stage 4 passed: only stage 4 counts.
      final result = _evaluate(
        today: _nov(10),
        logs: {..._every(_nov(1), 7, 14), ..._stage4()},
      )!;

      expect(result.windowEndDay, _nov(8));
      expect(result.outcome, StageOutcome.passed);
    });

    test('a stage that ended 2 days ago is checked', () {
      final result = _evaluate(
        today: _nov(10),
        logs: _stage4(over: {_nov(3): 12, _nov(4): 12}),
      )!;

      expect(result.outcome, StageOutcome.hold);
    });

    test('a stage that ended 3 days ago is skipped', () {
      final result = _evaluate(
        today: _nov(11),
        logs: _stage4(over: {_nov(3): 12, _nov(4): 12}),
      )!;

      expect(result.outcome, StageOutcome.skipped);
      expect(result.windowEndDay, _nov(8));
      expect(result.hold, isNull);
    });

    test('nothing is due before any stage has ended', () {
      expect(_evaluate(today: _oct(18)), isNull);
    });

    test('a waiting review card blocks the check', () {
      expect(
        _evaluate(
          today: _nov(9),
          checks: [_check(StageOutcome.review, _oct(25), answered: false)],
        ),
        isNull,
      );
    });

    test('a waiting reassess card blocks the check', () {
      expect(
        _evaluate(
          today: _nov(9),
          checks: [_check(StageOutcome.reassess, _oct(25), answered: false)],
        ),
        isNull,
      );
    });

    test('an answered review card does not', () {
      expect(
        _evaluate(
          today: _nov(9),
          checks: [_check(StageOutcome.review, _oct(25))],
        ),
        isNotNull,
      );
    });

    group('a stage that ended while a card waited is skipped', () {
      final failing = _stage4(over: {_nov(3): 12, _nov(4): 12});

      for (final outcome in [StageOutcome.review, StageOutcome.reassess]) {
        test('${outcome.name}, answered after the stage ended', () {
          final result = _evaluate(
            today: _nov(10),
            logs: failing,
            checks: [_check(outcome, _oct(25), answeredOn: _nov(9))],
          )!;

          // Nov 9 was seen at 8 a day; a hold from it would change it.
          expect(result.outcome, StageOutcome.skipped);
          expect(result.hold, isNull);
          expect(result.windowEndDay, _nov(8));
        });
      }

      test('a card answered on the stage’s last day is not', () {
        final result = _evaluate(
          today: _nov(9),
          logs: failing,
          checks: [_check(StageOutcome.review, _oct(25), answeredOn: _nov(8))],
        )!;

        expect(result.outcome, StageOutcome.hold);
      });

      test('a waiting hold card is not', () {
        final result = _evaluate(
          today: _nov(9),
          logs: failing,
          checks: [_check(StageOutcome.hold, _oct(25), answeredOn: _nov(9))],
        )!;

        expect(result.outcome, StageOutcome.review);
      });
    });
  });

  group('back near the start', () {
    // Window Oct 26 to Nov 1 at 9 a day (limit 8) after seven days at
    // [earlier] a day; the 14-day average must reach 9 of 10.
    StageCheckResult? run(int earlier, {int lastDayLess = 0}) => _evaluate(
      today: _nov(2),
      plan: _ten,
      logs: {
        ..._every(_oct(25), 7, earlier),
        ..._every(_nov(1), 7, 9),
        _nov(1): 9 - lastDayLess,
      },
    );

    test('exactly 90% of the first limit reassesses', () {
      final result = run(9)!;

      expect(result.logged, 63);
      expect(result.outcome, StageOutcome.reassess);
    });

    test('just under 90% is a hold', () {
      expect(run(9, lastDayLess: 1)!.outcome, StageOutcome.hold);
    });

    test('before 14 days into the plan is a hold', () {
      // Stage 2 ends Oct 25, 13 days after the start.
      final result = _evaluate(
        today: _oct(26),
        plan: _ten,
        logs: _every(_oct(25), 14, 10),
      )!;

      expect(result.windowEndDay, _oct(25));
      expect(result.outcome, StageOutcome.hold);
    });

    test('a plan on target is never reassessed', () {
      final result = _evaluate(
        today: _nov(2),
        plan: _ten,
        logs: {..._every(_oct(25), 7, 10), ..._every(_nov(1), 7, 8)},
      )!;

      expect(result.outcome, StageOutcome.passed);
    });
  });

  group('the streak', () {
    final failing = _stage4(over: {_nov(3): 12, _nov(4): 12});

    StageCheckResult run(List<StageCheck> checks) =>
        _evaluate(today: _nov(9), logs: failing, checks: checks)!;

    test('the first failure is a hold', () {
      expect(run(const []).outcome, StageOutcome.hold);
    });

    test('a hold then a failure is a review', () {
      final result = run([_check(StageOutcome.hold, _nov(1))]);

      expect(result.outcome, StageOutcome.review);
      expect(result.hold, isNull);
    });

    test('a pass in between resets it', () {
      final result = run([
        _check(StageOutcome.passed, _nov(1)),
        _check(StageOutcome.hold, _oct(25)),
      ]);

      expect(result.outcome, StageOutcome.hold);
    });

    test('a skipped check in between resets it', () {
      final result = run([
        _check(StageOutcome.skipped, _nov(1)),
        _check(StageOutcome.hold, _oct(25)),
      ]);

      expect(result.outcome, StageOutcome.hold);
    });

    test('after a kept review the next failure is a hold again', () {
      final result = run([
        _check(StageOutcome.review, _nov(1)),
        _check(StageOutcome.hold, _oct(25)),
      ]);

      expect(result.outcome, StageOutcome.hold);
    });

    test('checks of an earlier plan do not count', () {
      final result = run([
        _check(StageOutcome.hold, _nov(1), planStart: _oct(1)),
      ]);

      expect(result.outcome, StageOutcome.hold);
    });

    test('the order of the checks given does not matter', () {
      final result = run([
        _check(StageOutcome.hold, _oct(25)),
        _check(StageOutcome.passed, _nov(1)),
      ]);

      expect(result.outcome, StageOutcome.hold);
    });
  });

  group('the hold', () {
    final failing = _stage4(over: {_nov(3): 12, _nov(4): 12});

    test('starts the day after the stage ends', () {
      final result = _evaluate(today: _nov(9), logs: failing)!;

      expect(result.hold, PlanHold(startDay: _nov(9)));
    });

    test('also on a late open', () {
      final result = _evaluate(today: _nov(10), logs: failing)!;

      expect(result.outcome, StageOutcome.hold);
      expect(result.hold!.startDay, _nov(9));
    });

    test('is not made for a pass or a review', () {
      expect(_evaluate(today: _nov(9))!.hold, isNull);
    });

    test('a waiting hold card is closed by the next check', () {
      final result = _evaluate(
        today: _nov(9),
        logs: failing,
        checks: [_check(StageOutcome.hold, _nov(1), answered: false)],
      )!;

      expect(result.outcome, StageOutcome.review);
      expect(result.closesWaitingHold, isTrue);
    });

    test('a pass closes it too', () {
      final result = _evaluate(
        today: _nov(9),
        checks: [_check(StageOutcome.hold, _nov(1), answered: false)],
      )!;

      expect(result.outcome, StageOutcome.passed);
      expect(result.closesWaitingHold, isTrue);
    });

    test('an answered hold has nothing to close', () {
      final result = _evaluate(
        today: _nov(9),
        logs: failing,
        checks: [_check(StageOutcome.hold, _nov(1))],
      )!;

      expect(result.closesWaitingHold, isFalse);
    });

    test('a skipped check closes it too', () {
      final result = _evaluate(
        today: _nov(11),
        logs: failing,
        checks: [_check(StageOutcome.hold, _nov(1), answered: false)],
      )!;

      expect(result.outcome, StageOutcome.skipped);
      expect(result.closesWaitingHold, isTrue);
    });

    test('a stage lengthened by a hold ends later', () {
      final held = ReductionPlan(
        startDay: _oct(12),
        startLimit: 12,
        quitDay: _jan(4),
        holds: [PlanHold(startDay: _nov(9))],
      );

      // Stage 4 now runs to Nov 15, so Nov 9 has nothing to check yet.
      expect(
        _evaluate(
          today: _nov(9),
          plan: held,
          checks: [_check(StageOutcome.hold, _nov(8), answered: false)],
        ),
        isNull,
      );
    });
  });
}

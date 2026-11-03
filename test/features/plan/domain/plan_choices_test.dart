import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/plan/domain/entities/plan_hold.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/plan/domain/services/plan_choices.dart';
import 'package:flutter_test/flutter_test.dart';

LogicalDay _oct(int day) => LogicalDay(2026, 10, day);
LogicalDay _nov(int day) => LogicalDay(2026, 11, day);
LogicalDay _jan(int day) => LogicalDay(2027, 1, day);
LogicalDay _feb(int day) => LogicalDay(2027, 2, day);
LogicalDay _mar(int day) => LogicalDay(2027, 3, day);

/// 12 a day from Oct 12, quit Jan 4: a drop every 7 days.
ReductionPlan _plan({List<PlanHold> holds = const []}) => ReductionPlan(
  startDay: _oct(12),
  startLimit: 12,
  quitDay: _jan(4),
  holds: holds,
);

PlanChoice _choice(List<PlanChoice> choices, ChoiceKind kind) =>
    choices.singleWhere((c) => c.kind == kind);

void main() {
  group('review (AC)', () {
    // A hold from Nov 9 moves the quit date to Jan 11; today is Nov 16.
    final choices = PlanChoices.review(
      current: _plan(holds: [PlanHold(startDay: _nov(9))]),
      today: _nov(16),
      windowAverage: 11,
      checkedLimit: 9,
    );

    test('offers the real number, slow down and keep, in that order', () {
      expect(choices.map((c) => c.kind), [
        ChoiceKind.realNumber,
        ChoiceKind.slowDown,
        ChoiceKind.keep,
      ]);
    });

    test('start from the real number', () {
      final choice = _choice(choices, ChoiceKind.realNumber);

      expect(choice.limit, 11);
      expect(choice.quitDay, _feb(1));
      expect(choice.daysPerDrop, 7);
      expect(choice.changeDays, 21);
    });

    test("slow down at the checked stage's limit, at double the pace", () {
      final choice = _choice(choices, ChoiceKind.slowDown);

      expect(choice.limit, 9);
      expect(choice.quitDay, _mar(22));
      expect(choice.daysPerDrop, 14);
      expect(choice.changeDays, 70);
    });

    test('keep leaves the plan as it is today', () {
      final choice = _choice(choices, ChoiceKind.keep);

      expect(choice.limit, 8);
      expect(choice.quitDay, _jan(11));
      expect(choice.daysPerDrop, 7);
      expect(choice.changeDays, 0);
    });
  });

  group('reassess (AD)', () {
    final choices = PlanChoices.reassess(
      current: _plan(),
      today: _nov(9),
      average: 12,
    );

    test('offers start again and keep', () {
      expect(choices.map((c) => c.kind), [
        ChoiceKind.startAgain,
        ChoiceKind.keep,
      ]);
    });

    test('start again from the average', () {
      final choice = _choice(choices, ChoiceKind.startAgain);

      expect(choice.limit, 12);
      expect(choice.quitDay, _feb(1));
      expect(choice.daysPerDrop, 7);
      expect(choice.changeDays, 28);
    });

    test('keep leaves the plan as it is', () {
      final choice = _choice(choices, ChoiceKind.keep);

      expect(choice.limit, 8);
      expect(choice.quitDay, _jan(4));
      expect(choice.changeDays, 0);
    });

    test('keeps the current quit date when it is later than suggested', () {
      final far = PlanChoices.reassess(
        current: _plan(holds: [PlanHold(startDay: _nov(9))]),
        today: _nov(9),
        average: 3,
      );

      // Suggested: 3 × 7 = 21 days, to Nov 30. The plan quits on Jan 11.
      final choice = _choice(far, ChoiceKind.startAgain);
      expect(choice.limit, 3);
      expect(choice.quitDay, _jan(11));
      expect(choice.changeDays, 0);
      expect(choice.daysPerDrop, closeTo(63 / 3, 1e-9));
    });
  });

  group('numbers', () {
    test('a limit above 80 is capped at 80', () {
      final choices = PlanChoices.review(
        current: _plan(),
        today: _nov(16),
        windowAverage: 120,
        checkedLimit: 9,
      );

      expect(_choice(choices, ChoiceKind.realNumber).limit, 80);
    });

    test('the reassess limit is capped at 80 too', () {
      final choices = PlanChoices.reassess(
        current: _plan(),
        today: _nov(9),
        average: 95,
      );

      expect(_choice(choices, ChoiceKind.startAgain).limit, 80);
    });

    test('the length is rounded up to whole days', () {
      // 70 days over 9 a day is 7.78 days a drop; 4 a day is 31.11 days.
      final plan = ReductionPlan(
        startDay: _oct(12),
        startLimit: 9,
        quitDay: _oct(12).addDays(70),
      );

      final choices = PlanChoices.review(
        current: plan,
        today: _nov(16),
        windowAverage: 4,
        checkedLimit: 4,
      );

      expect(
        _choice(choices, ChoiceKind.realNumber).quitDay,
        _nov(16).addDays(32),
      );
      expect(
        _choice(choices, ChoiceKind.slowDown).quitDay,
        _nov(16).addDays(63),
      );
    });

    test('a whole-number length is not rounded up', () {
      // 70 days over 9 a day: nine drops of 70/9, so 9 a day is exactly 70.
      final plan = ReductionPlan(
        startDay: _oct(12),
        startLimit: 9,
        quitDay: _oct(12).addDays(70),
      );

      final choices = PlanChoices.review(
        current: plan,
        today: _nov(16),
        windowAverage: 9,
        checkedLimit: 9,
      );

      expect(
        _choice(choices, ChoiceKind.realNumber).quitDay,
        _nov(16).addDays(70),
      );
    });

    test('a pace under 1.5 days drops about every day', () {
      final fast = ReductionPlan(
        startDay: _oct(12),
        startLimit: 10,
        quitDay: _oct(12).addDays(14),
      );

      final choices = PlanChoices.review(
        current: fast,
        today: _oct(20),
        windowAverage: 6,
        checkedLimit: 6,
      );

      expect(_choice(choices, ChoiceKind.realNumber).dropsAboutDaily, isTrue);
      expect(_choice(choices, ChoiceKind.slowDown).dropsAboutDaily, isFalse);
      expect(_choice(choices, ChoiceKind.keep).dropsAboutDaily, isTrue);
    });

    test('a pace of 1.5 days or more does not', () {
      final choices = PlanChoices.review(
        current: _plan(),
        today: _nov(16),
        windowAverage: 11,
        checkedLimit: 9,
      );

      expect(_choice(choices, ChoiceKind.realNumber).dropsAboutDaily, isFalse);
    });
  });
}

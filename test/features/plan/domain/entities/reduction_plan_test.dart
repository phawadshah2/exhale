import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/plan/domain/entities/plan_stage.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final oct15 = LogicalDay(2026, 10, 15);
  final oct19 = LogicalDay(2026, 10, 19);

  // 9/day over 63 days: exactly one fewer every 7 days (the old weekly plan).
  final weekly = ReductionPlan(
    startDay: oct15,
    startLimit: 9,
    quitDay: LogicalDay(2026, 12, 17),
  );

  // 9/day quitting 8 weeks out: drops spread unevenly, about every 6 days.
  final eightWeeks = ReductionPlan(
    startDay: oct19,
    startLimit: 9,
    quitDay: LogicalDay(2026, 12, 14),
  );

  // 9/day quitting in 5 days: more than one fewer a day.
  final steep = ReductionPlan(
    startDay: oct19,
    startLimit: 9,
    quitDay: oct19.addDays(5),
  );

  List<int> limits(ReductionPlan plan, {int extraDays = 0}) => [
    for (var d = 0; d <= plan.totalDays + extraDays; d++)
      plan.limitOn(plan.startDay.addDays(d)),
  ];

  group('limitOn', () {
    test('a 63-day plan from 9 drops by one every 7 days', () {
      final values = limits(weekly);

      for (var d = 0; d < 63; d++) {
        expect(values[d], 9 - d ~/ 7, reason: 'day $d');
      }
      expect(values[63], 0);
    });

    test('an 8-week plan spreads drops evenly', () {
      expect(eightWeeks.limitOn(LogicalDay(2026, 10, 25)), 9);
      expect(eightWeeks.limitOn(LogicalDay(2026, 10, 26)), 8);
      expect(eightWeeks.limitOn(LogicalDay(2026, 11, 1)), 7);
      expect(eightWeeks.limitOn(LogicalDay(2026, 11, 7)), 6);
      expect(eightWeeks.limitOn(LogicalDay(2026, 12, 7)), 2);
      expect(eightWeeks.limitOn(LogicalDay(2026, 12, 8)), 1);
      expect(eightWeeks.limitOn(LogicalDay(2026, 12, 13)), 1);
      expect(eightWeeks.limitOn(LogicalDay(2026, 12, 14)), 0);
    });

    test('a steep plan drops by more than one a day', () {
      expect(limits(steep), [9, 8, 6, 4, 2, 0]);
    });

    test('never rises, and is 0 from the quit day on', () {
      for (final plan in [weekly, eightWeeks, steep]) {
        final values = limits(plan, extraDays: 30);
        for (var i = 1; i < values.length; i++) {
          expect(values[i], lessThanOrEqualTo(values[i - 1]));
        }
        expect(values.skip(plan.totalDays), everyElement(0));
      }
    });

    test('uses the start limit before the plan begins', () {
      expect(eightWeeks.limitOn(oct19.addDays(-3)), 9);
    });
  });

  group('stages', () {
    test('weekly plan has nine 7-day stages', () {
      expect(weekly.stageCount, 9);
      expect(
        weekly.stages.first,
        PlanStage(number: 1, limit: 9, startDay: oct15, lengthDays: 7),
      );
      expect(weekly.stages.last.limit, 1);
      expect(weekly.stages.last.startDay, LogicalDay(2026, 12, 10));
      expect(weekly.stages.last.endDay, LogicalDay(2026, 12, 16));
    });

    test('uneven plans have stages of different lengths', () {
      expect(eightWeeks.stages.map((s) => s.limit), [
        9,
        8,
        7,
        6,
        5,
        4,
        3,
        2,
        1,
      ]);
      expect(eightWeeks.stages.first.lengthDays, 7);
      expect(eightWeeks.stages[1].lengthDays, 6);
      expect(
        eightWeeks.stages.fold<int>(0, (sum, s) => sum + s.lengthDays),
        eightWeeks.totalDays,
      );
    });

    test('a steep plan skips limits', () {
      expect(steep.stages.map((s) => s.limit), [9, 8, 6, 4, 2]);
    });

    test('stageOn agrees with limitOn on every plan day', () {
      for (final plan in [weekly, eightWeeks, steep]) {
        for (var d = 0; d < plan.totalDays; d++) {
          final day = plan.startDay.addDays(d);
          expect(plan.stageOn(day)!.limit, plan.limitOn(day), reason: '$day');
        }
        expect(plan.stageOn(plan.quitDay), isNull);
        expect(plan.stageOn(plan.startDay.addDays(-1)), isNull);
      }
    });

    test('are read-only', () {
      expect(
        () => weekly.stages.add(weekly.stages.first),
        throwsUnsupportedError,
      );
    });
  });

  group('next drop', () {
    test('points at the next stage', () {
      expect(eightWeeks.nextDropOn(oct19), LogicalDay(2026, 10, 26));
      expect(eightWeeks.daysUntilNextDrop(oct19), 7);
      expect(
        eightWeeks.nextDropOn(LogicalDay(2026, 10, 26)),
        LogicalDay(2026, 11, 1),
      );
    });

    test('the last drop is the quit day', () {
      expect(
        eightWeeks.nextDropOn(LogicalDay(2026, 12, 10)),
        eightWeeks.quitDay,
      );
      expect(eightWeeks.limitOn(eightWeeks.quitDay), 0);
    });

    test('before the start it is the first drop', () {
      expect(
        eightWeeks.nextDropOn(oct19.addDays(-2)),
        LogicalDay(2026, 10, 26),
      );
    });

    test('is null from the quit day', () {
      expect(eightWeeks.nextDropOn(eightWeeks.quitDay), isNull);
      expect(
        eightWeeks.daysUntilNextDrop(eightWeeks.quitDay.addDays(9)),
        isNull,
      );
    });
  });

  group('projection', () {
    test('planned reduction matches the designed weekly plan', () {
      expect(weekly.plannedReduction, 252);
    });

    test('planned reduction sums the daily savings', () {
      expect(steep.plannedReduction, 0 + 1 + 3 + 5 + 7);
    });

    test('days per drop', () {
      expect(weekly.daysPerDrop, 7);
      expect(steep.daysPerDrop, closeTo(5 / 9, 1e-9));
    });

    test('progress runs from 0 to 1 and is clamped', () {
      expect(weekly.progressOn(oct15), 0);
      expect(weekly.progressOn(oct15.addDays(-5)), 0);
      expect(weekly.progressOn(weekly.quitDay), 1);
      expect(weekly.progressOn(weekly.quitDay.addDays(40)), 1);
    });

    test('suggested quit day is about one fewer per week', () {
      expect(ReductionPlan.suggestedQuitDay(oct19, 9), oct19.addDays(63));
      expect(ReductionPlan.suggestedQuitDay(oct19, 1), oct19.addDays(7));
    });

    test('flags start and completion', () {
      expect(eightWeeks.hasStartedOn(oct19.addDays(-1)), isFalse);
      expect(eightWeeks.hasStartedOn(oct19), isTrue);
      expect(eightWeeks.isCompleteOn(LogicalDay(2026, 12, 13)), isFalse);
      expect(eightWeeks.isCompleteOn(LogicalDay(2026, 12, 14)), isTrue);
    });
  });

  group('validation', () {
    test('rejects a start limit below 1', () {
      expect(
        () => ReductionPlan(
          startDay: oct19,
          startLimit: 0,
          quitDay: oct19.addDays(10),
        ),
        throwsArgumentError,
      );
    });

    test('rejects a quit day on or before the start', () {
      expect(
        () => ReductionPlan(startDay: oct19, startLimit: 9, quitDay: oct19),
        throwsArgumentError,
      );
    });
  });

  test('equality is by value', () {
    final copy = ReductionPlan(
      startDay: oct15,
      startLimit: 9,
      quitDay: LogicalDay(2026, 12, 17),
    );
    expect(copy, weekly);
    expect(copy.hashCode, weekly.hashCode);
    expect(eightWeeks, isNot(weekly));
  });
}

import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/plan/domain/entities/plan_stage.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The plan shown in the Stitch designs: 9/day from 15 Oct 2026, minus one
  // every 7 days, reaching 0 on 17 Dec 2026.
  final start = LogicalDay(2026, 10, 15);
  final plan = ReductionPlan(startDay: start, startLimit: 9);

  LogicalDay day(int offset) => start.addDays(offset);

  group('ReductionPlan defaults', () {
    test('steps every 7 days towards zero', () {
      expect(plan.stepDays, 7);
      expect(plan.targetLimit, 0);
    });
  });

  group('limitOn', () {
    test('holds the start limit for the first stage', () {
      expect(plan.limitOn(day(0)), 9);
      expect(plan.limitOn(day(6)), 9);
    });

    test('drops by one on each step day', () {
      expect(plan.limitOn(day(7)), 8);
      expect(plan.limitOn(day(13)), 8);
      expect(plan.limitOn(day(14)), 7);
      expect(plan.limitOn(day(62)), 1);
    });

    test('reaches the target and stays there', () {
      expect(plan.limitOn(day(63)), 0);
      expect(plan.limitOn(day(400)), 0);
    });

    test('uses the start limit before the plan begins', () {
      expect(plan.limitOn(day(-3)), 9);
    });

    test('stops at a custom target', () {
      final custom = ReductionPlan(
        startDay: start,
        startLimit: 10,
        stepDays: 3,
        targetLimit: 4,
      );

      expect(custom.limitOn(day(2)), 10);
      expect(custom.limitOn(day(3)), 9);
      expect(custom.limitOn(day(17)), 5);
      expect(custom.limitOn(day(18)), 4);
      expect(custom.limitOn(day(100)), 4);
      expect(custom.targetDay, day(18));
    });
  });

  group('timeline', () {
    test('matches the designed schedule', () {
      expect(plan.stageCount, 9);
      expect(plan.totalDays, 63);
      expect(plan.targetDay, LogicalDay(2026, 12, 17));
    });

    test('stages cover every limit above the target', () {
      final stages = plan.stages;

      expect(stages, hasLength(9));
      expect(
        stages.first,
        PlanStage(number: 1, limit: 9, startDay: start, lengthDays: 7),
      );
      expect(stages.first.endDay, LogicalDay(2026, 10, 21));
      expect(stages[2].limit, 7);
      expect(stages[2].startDay, LogicalDay(2026, 10, 29));
      expect(stages.last.number, 9);
      expect(stages.last.limit, 1);
      expect(stages.last.startDay, LogicalDay(2026, 12, 10));
      expect(stages.last.endDay, LogicalDay(2026, 12, 16));
    });

    test('stages are read-only', () {
      expect(() => plan.stages.add(plan.stages.first), throwsUnsupportedError);
    });
  });

  group('stageOn', () {
    test('returns the active stage and day within it', () {
      final stage = plan.stageOn(LogicalDay(2026, 10, 18))!;

      expect(stage.number, 1);
      expect(stage.dayNumberOf(LogicalDay(2026, 10, 18)), 4);
      expect(plan.stageOn(LogicalDay(2026, 10, 29))!.number, 3);
      expect(plan.stageOn(LogicalDay(2026, 12, 16))!.number, 9);
    });

    test('is null before the start and once complete', () {
      expect(plan.stageOn(day(-1)), isNull);
      expect(plan.stageOn(plan.targetDay), isNull);
    });

    test('agrees with limitOn on every plan day', () {
      for (var i = 0; i < plan.totalDays; i++) {
        final stage = plan.stageOn(day(i))!;

        expect(stage.limit, plan.limitOn(day(i)), reason: '${day(i)}');
        expect(stage.contains(day(i)), isTrue, reason: '${day(i)}');
      }
    });
  });

  group('next drop', () {
    test('points at the next step day', () {
      expect(plan.nextDropOn(day(0)), LogicalDay(2026, 10, 22));
      expect(plan.daysUntilNextDrop(day(0)), 7);
      expect(plan.daysUntilNextDrop(day(4)), 3);
      expect(plan.daysUntilNextDrop(day(6)), 1);
      expect(plan.nextDropOn(day(7)), LogicalDay(2026, 10, 29));
    });

    test('the last drop lands on the target day', () {
      expect(plan.nextDropOn(LogicalDay(2026, 12, 16)), plan.targetDay);
    });

    test('before the start it is the first step day', () {
      expect(plan.nextDropOn(day(-5)), day(7));
      expect(plan.daysUntilNextDrop(day(-5)), 12);
    });

    test('is null once complete', () {
      expect(plan.nextDropOn(plan.targetDay), isNull);
      expect(plan.daysUntilNextDrop(day(100)), isNull);
    });
  });

  group('progress', () {
    final even = ReductionPlan(startDay: start, startLimit: 4, stepDays: 5);

    test('runs from 0 at the start to 1 at the target', () {
      expect(even.progressOn(day(0)), 0);
      expect(even.progressOn(day(10)), 0.5);
      expect(even.progressOn(even.targetDay), 1);
    });

    test('is clamped outside the plan', () {
      expect(even.progressOn(day(-10)), 0);
      expect(even.progressOn(day(500)), 1);
    });

    test('flags start and completion', () {
      expect(plan.hasStartedOn(day(-1)), isFalse);
      expect(plan.hasStartedOn(day(0)), isTrue);
      expect(plan.isCompleteOn(day(62)), isFalse);
      expect(plan.isCompleteOn(day(63)), isTrue);
    });
  });

  group('validation', () {
    test('rejects a start limit not above the target', () {
      expect(
        () => ReductionPlan(startDay: start, startLimit: 0),
        throwsArgumentError,
      );
      expect(
        () => ReductionPlan(startDay: start, startLimit: 3, targetLimit: 3),
        throwsArgumentError,
      );
    });

    test('rejects a negative target', () {
      expect(
        () => ReductionPlan(startDay: start, startLimit: 3, targetLimit: -1),
        throwsArgumentError,
      );
    });

    test('rejects a step shorter than one day', () {
      expect(
        () => ReductionPlan(startDay: start, startLimit: 3, stepDays: 0),
        throwsArgumentError,
      );
    });
  });

  test('equality is by value', () {
    expect(ReductionPlan(startDay: start, startLimit: 9), plan);
    expect(
      ReductionPlan(startDay: start, startLimit: 9).hashCode,
      plan.hashCode,
    );
    expect(ReductionPlan(startDay: start, startLimit: 8), isNot(plan));
  });
}

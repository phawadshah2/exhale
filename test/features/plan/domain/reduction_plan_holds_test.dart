import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/plan/domain/entities/plan_hold.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:flutter_test/flutter_test.dart';

LogicalDay _oct(int day) => LogicalDay(2026, 10, day);
LogicalDay _nov(int day) => LogicalDay(2026, 11, day);
LogicalDay _dec(int day) => LogicalDay(2026, 12, day);
LogicalDay _jan(int day) => LogicalDay(2027, 1, day);

/// 12 a day from Oct 12, quit Jan 4: 84 days, one drop every 7 days.
ReductionPlan _plan({List<PlanHold> holds = const []}) => ReductionPlan(
  startDay: _oct(12),
  startLimit: 12,
  quitDay: _jan(4),
  holds: holds,
);

void main() {
  final hold = PlanHold(startDay: _nov(9));

  group('one hold after stage 4', () {
    final plan = _plan(holds: [hold]);

    test('stage 4 runs Nov 2 to 15 and the stage count stays 12', () {
      final stage = plan.stages[3];

      expect(stage.number, 4);
      expect(stage.limit, 9);
      expect(stage.startDay, _nov(2));
      expect(stage.lengthDays, 14);
      expect(stage.endDay, _nov(15));
      expect(plan.stageCount, 12);
      expect(plan.stages[4].startDay, _nov(16));
      expect(plan.stages[4].limit, 8);
    });

    test('the limit holds for the extra week, then goes on', () {
      expect(plan.limitOn(_nov(1)), 10);
      expect(plan.limitOn(_nov(8)), 9);
      expect(plan.limitOn(_nov(9)), 9);
      expect(plan.limitOn(_nov(15)), 9);
      expect(plan.limitOn(_nov(16)), 8);
    });

    test('quitDay includes the hold, agreedQuitDay does not', () {
      expect(plan.quitDay, _jan(11));
      expect(plan.agreedQuitDay, _jan(4));
      expect(plan.totalDays, 91);
    });

    test('daysPerDrop ignores held days', () {
      expect(plan.daysPerDrop, 7);
    });

    test('every later day reads the taper seven days earlier', () {
      final base = _plan();
      for (var d = 0; d < 80; d++) {
        final day = _nov(16).addDays(d);
        expect(
          plan.limitOn(day),
          base.limitOn(day.addDays(-7)),
          reason: '$day',
        );
      }
    });

    test('nextDropOn and stageOn follow the longer stage', () {
      expect(plan.stageOn(_nov(12))!.number, 4);
      expect(plan.nextDropOn(_nov(5)), _nov(16));
      expect(plan.nextDropOn(_nov(12)), _nov(16));
      expect(plan.nextDropOn(_nov(16)), _nov(23));
      expect(plan.nextDropOn(_jan(11)), isNull);
    });

    test('plannedReduction counts the extra days at the held limit', () {
      // Seven more days at 9 a day, each 3 under the start limit of 12.
      expect(plan.plannedReduction, _plan().plannedReduction + 7 * 3);
    });
  });

  group('more holds', () {
    test('two holds add up', () {
      final plan = _plan(
        holds: [
          PlanHold(startDay: _nov(23)),
          hold,
        ],
      );

      expect(plan.quitDay, _jan(18));
      expect(plan.stages[4].startDay, _nov(16));
      expect(plan.stages[4].lengthDays, 14);
      expect(plan.limitOn(_nov(22)), 8);
      expect(plan.limitOn(_nov(29)), 8);
      expect(plan.limitOn(_nov(30)), 7);
      expect(plan.stageCount, 12);
    });

    test('a hold at the end of the first stage', () {
      final plan = _plan(holds: [PlanHold(startDay: _oct(19))]);

      expect(plan.stages.first.lengthDays, 14);
      expect(plan.limitOn(_oct(25)), 12);
      expect(plan.limitOn(_oct(26)), 11);
      expect(plan.quitDay, _jan(11));
    });

    test('a hold on the last stage keeps 1 a day, then zero', () {
      final plan = _plan(holds: [PlanHold(startDay: _jan(4))]);

      expect(plan.limitOn(_jan(3)), 1);
      expect(plan.limitOn(_jan(4)), 1);
      expect(plan.limitOn(_jan(10)), 1);
      expect(plan.limitOn(_jan(11)), 0);
      expect(plan.stages.last.limit, 1);
      expect(plan.stages.last.lengthDays, 14);
      expect(plan.quitDay, _jan(11));
    });

    test('a hold on a stage under seven days long', () {
      // 12 a day over 12 days: every stage is one day.
      final plan = ReductionPlan(
        startDay: _oct(12),
        startLimit: 12,
        quitDay: _oct(24),
        holds: [PlanHold(startDay: _oct(15))],
      );

      expect(plan.stageCount, 12);
      expect(plan.stages[2].limit, 10);
      expect(plan.stages[2].startDay, _oct(14));
      expect(plan.stages[2].lengthDays, 8);
      expect(plan.limitOn(_oct(21)), 10);
      expect(plan.limitOn(_oct(22)), 9);
      expect(plan.quitDay, _oct(31));
    });

    test('a hold on a stage over seven days long', () {
      // 12 a day over 120 days: every stage is ten days.
      final plan = ReductionPlan(
        startDay: _oct(12),
        startLimit: 12,
        quitDay: _oct(12).addDays(120),
        holds: [PlanHold(startDay: _oct(22))],
      );

      expect(plan.stages.first.lengthDays, 17);
      expect(plan.stages[1].startDay, _oct(29));
      expect(plan.stages[1].limit, 11);
      expect(plan.stageCount, 12);
      expect(plan.daysPerDrop, 10);
    });

    test('a hold in a different order is the same plan', () {
      final later = PlanHold(startDay: _nov(23));

      expect(_plan(holds: [hold, later]), _plan(holds: [later, hold]));
    });
  });

  group('without holds', () {
    final shapes = [
      (_oct(12), 12, _jan(4)),
      (_oct(14), 9, _oct(14).addDays(63)),
      (_oct(14), 1, _oct(15)),
      (_oct(14), 1, _oct(14).addDays(14)),
      (_oct(14), 80, _oct(14).addDays(560)),
      (_oct(14), 7, _oct(14).addDays(10)),
      (_oct(14), 3, _dec(31)),
    ];

    for (final (start, limit, quit) in shapes) {
      test('$limit a day from $start to $quit is unchanged', () {
        final plan = ReductionPlan(
          startDay: start,
          startLimit: limit,
          quitDay: quit,
        );
        final days = quit.daysSince(start);

        expect(plan.quitDay, quit);
        expect(plan.agreedQuitDay, quit);
        expect(plan.holds, isEmpty);
        for (var d = -2; d <= days + 3; d++) {
          final expected = d <= 0
              ? limit
              : d >= days
              ? 0
              : (limit * (days - d) + days - 1) ~/ days;
          expect(plan.limitOn(start.addDays(d)), expected, reason: 'day $d');
        }
      });
    }
  });

  group('value', () {
    test('equality includes holds', () {
      expect(_plan(holds: [hold]), _plan(holds: [hold]));
      expect(_plan(holds: [hold]), isNot(_plan()));
      expect(
        _plan(holds: [hold]),
        isNot(_plan(holds: [PlanHold(startDay: _nov(16))])),
      );
      expect(_plan(holds: [hold]).hashCode, _plan(holds: [hold]).hashCode);
    });

    test('a hold lasts seven days unless said otherwise', () {
      expect(hold.days, 7);
      expect(PlanHold(startDay: _nov(9), days: 3).days, 3);
      expect(PlanHold(startDay: _nov(9)), PlanHold(startDay: _nov(9)));
      expect(PlanHold(startDay: _nov(9)), isNot(PlanHold(startDay: _nov(10))));
    });
  });
}

import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final oct15 = LogicalDay(2026, 10, 15);
  final oct29 = LogicalDay(2026, 10, 29);
  final original = ReductionPlan(startDay: oct15, startLimit: 9);

  group('PlanHistory', () {
    test('with one plan it behaves like that plan', () {
      final history = PlanHistory([original]);

      expect(history.current, original);
      expect(history.firstDay, oct15);
      expect(
        history.limitOn(oct15.addDays(20)),
        original.limitOn(oct15.addDays(20)),
      );
    });

    test('days before the first plan use the first plan', () {
      final history = PlanHistory([original]);

      expect(history.planOn(oct15.addDays(-3)), original);
      expect(history.limitOn(oct15.addDays(-3)), 9);
    });

    test('a replan changes the future but keeps past limits', () {
      // On 29 Oct the original plan is at 7/day; the user restarts at 5.
      final restart = ReductionPlan(startDay: oct29, startLimit: 5);
      final history = PlanHistory([original]).replan(restart);

      expect(history.plans, [original, restart]);
      expect(history.current, restart);
      expect(history.limitOn(oct29.addDays(-1)), 8);
      expect(history.limitOn(oct29), 5);
      expect(history.limitOn(oct29.addDays(7)), 4);
    });

    test('replanning on the same day replaces that plan', () {
      final first = PlanHistory([original]);
      final sameDay = ReductionPlan(startDay: oct15, startLimit: 12);

      expect(first.replan(sameDay).plans, [sameDay]);
    });

    test('replanning earlier drops the plans that started later', () {
      final later = ReductionPlan(startDay: oct29, startLimit: 5);
      final earlier = ReductionPlan(startDay: oct15.addDays(7), startLimit: 6);
      final history = PlanHistory([original, later]).replan(earlier);

      expect(history.plans, [original, earlier]);
    });

    test('sorts plans by start day', () {
      final later = ReductionPlan(startDay: oct29, startLimit: 5);

      expect(PlanHistory([later, original]).plans, [original, later]);
    });

    test('plans list is read-only', () {
      final history = PlanHistory([original]);

      expect(() => history.plans.add(original), throwsUnsupportedError);
    });

    test('rejects an empty history', () {
      expect(() => PlanHistory(const []), throwsArgumentError);
    });

    test('rejects two plans starting on the same day', () {
      final clash = ReductionPlan(startDay: oct15, startLimit: 5);

      expect(() => PlanHistory([original, clash]), throwsArgumentError);
    });
  });
}

import 'package:exhale/features/tracking/domain/entities/habit_log.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:exhale/features/tracking/domain/services/progress_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  var nextId = 1;

  HabitLog logWith(Trigger? trigger) => HabitLog(
    id: nextId++,
    habitId: 1,
    loggedAt: DateTime(2026, 10, 16, 9),
    trigger: trigger,
  );

  group('triggerBreakdown', () {
    test('shares are fractions of every log, sorted by count', () {
      final breakdown = ProgressCalculator.triggerBreakdown([
        logWith(Trigger.work),
        logWith(Trigger.stress),
        logWith(null),
        logWith(Trigger.stress),
      ]);

      expect(breakdown.total, 4);
      expect(breakdown.noTrigger, 1);
      expect(breakdown.shares.map((s) => s.trigger), [
        Trigger.stress,
        Trigger.work,
      ]);
      expect(breakdown.shares[0].count, 2);
      expect(breakdown.shares[0].fraction, closeTo(0.5, 1e-9));
      expect(breakdown.shares[1].fraction, closeTo(0.25, 1e-9));
    });

    test('top leaves out no-trigger logs and caps at n', () {
      final breakdown = ProgressCalculator.triggerBreakdown([
        logWith(Trigger.work),
        logWith(Trigger.stress),
        logWith(null),
        logWith(null),
        logWith(null),
        logWith(Trigger.stress),
      ]);

      expect(breakdown.top(3), hasLength(2));
      expect(breakdown.top(1).single.trigger, Trigger.stress);
    });

    test('ties follow the enum order', () {
      final breakdown = ProgressCalculator.triggerBreakdown([
        logWith(Trigger.stress),
        logWith(Trigger.coffee),
      ]);

      expect(breakdown.shares.map((s) => s.trigger), [
        Trigger.coffee,
        Trigger.stress,
      ]);
    });

    test('no logs gives an empty breakdown', () {
      final breakdown = ProgressCalculator.triggerBreakdown(const []);

      expect(breakdown.total, 0);
      expect(breakdown.noTrigger, 0);
      expect(breakdown.shares, isEmpty);
      expect(breakdown.top(3), isEmpty);
    });
  });
}

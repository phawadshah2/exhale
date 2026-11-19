import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/settings/domain/plan_tile_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = LogicalDay(2026, 11, 19);
  final quit = LogicalDay(2027, 1, 12);
  final habit = TrackedHabit(
    id: 1,
    habit: Habit.vaping,
    createdAt: DateTime(2026, 11, 19),
  );
  final history = PlanHistory([
    ReductionPlan(startDay: start, startLimit: 12, quitDay: quit),
  ]);

  TileSummary on(LogicalDay today) =>
      planTileSummary(habit: habit, history: history, today: today);

  test('eyebrow names the habit', () {
    expect(on(start).eyebrow, 'Vaping plan');
  });

  test('54 days to go', () {
    expect(on(start).value, 'Jan 12');
    expect(on(start).line, '54 days to go');
  });

  test('VoiceOver reads the quit date in full', () {
    expect(
      on(start).semanticsLabel,
      'Vaping plan, quit January 12, 54 days to go',
    );
  });

  test('1 day to go', () {
    expect(on(LogicalDay(2027, 1, 11)).line, '1 day to go');
  });

  test('quit day reached says Quit day', () {
    final summary = on(LogicalDay(2027, 1, 20));
    expect(summary.value, 'Quit day');
    expect(summary.line, 'Jan 12');
  });

  test('a plan starting tomorrow says Starts', () {
    final summary = on(LogicalDay(2026, 11, 18));
    expect(summary.value, 'Jan 12');
    expect(summary.line, 'Starts Nov 19');
  });
}

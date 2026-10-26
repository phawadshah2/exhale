import 'package:exhale/core/domain/time/day_boundary.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/tracking/domain/entities/habit_log.dart';
import 'package:exhale/features/tracking/domain/entities/period_range.dart';
import 'package:exhale/features/tracking/domain/services/progress_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Plan starts Wed 14 Oct 2026 at 9/day and quits on 16 Dec.
  final start = LogicalDay(2026, 10, 14);
  final history = PlanHistory([
    ReductionPlan(
      startDay: start,
      startLimit: 9,
      quitDay: start.addDays(9 * 7),
    ),
  ]);
  const boundary = DayBoundary();
  final today = LogicalDay(2026, 10, 16);
  final week = PeriodRange.weekOf(today);
  var nextId = 1;

  List<HabitLog> logsOn(LogicalDay day, int count) => [
    for (var i = 0; i < count; i++)
      HabitLog(
        id: nextId++,
        loggedAt: DateTime(day.year, day.month, day.day, 9 + i),
        habitId: 1,
      ),
  ];

  group('periodStats', () {
    test('week allowed and under', () {
      final stats = ProgressCalculator.periodStats(
        range: week,
        logs: [
          ...logsOn(start, 6),
          ...logsOn(start.addDays(1), 6),
          ...logsOn(today, 4),
        ],
        boundary: boundary,
        history: history,
        today: today,
      );

      expect(stats.logged, 16);
      expect(stats.allowed, 45);
      expect(stats.allowedByToday, 27);
      expect(stats.underBy, 11);
      expect(stats.avgPerDay, closeTo(16 / 3, 1e-9));
      expect(stats.daysOver, 0);
      expect(stats.daysOnTrack, 3);
    });

    test('a day at its limit is on track, past it is over', () {
      final stats = ProgressCalculator.periodStats(
        range: week,
        logs: [
          ...logsOn(start, 6),
          ...logsOn(start.addDays(1), 11),
          ...logsOn(today, 9),
        ],
        boundary: boundary,
        history: history,
        today: today,
      );

      expect(stats.logged, 26);
      expect(stats.underBy, 1);
      expect(stats.daysOver, 1);
      expect(stats.daysOnTrack, 2);
    });

    test('log at 01:30 counts to the previous day', () {
      // Mon 19 Oct 01:30 still belongs to Sun 18 Oct.
      final lateNight = [
        HabitLog(
          id: nextId++,
          habitId: 1,
          loggedAt: DateTime(2026, 10, 19, 1, 30),
        ),
      ];
      final laterToday = LogicalDay(2026, 10, 20);

      final thisWeek = ProgressCalculator.periodStats(
        range: week,
        logs: lateNight,
        boundary: boundary,
        history: history,
        today: laterToday,
      );
      final nextWeek = ProgressCalculator.periodStats(
        range: PeriodRange.weekOf(laterToday),
        logs: lateNight,
        boundary: boundary,
        history: history,
        today: laterToday,
      );

      expect(thisWeek.logged, 1);
      expect(nextWeek.logged, 0);
    });

    test("plan edited mid-week keeps earlier days' limits", () {
      final replanned = history.replan(
        ReductionPlan(
          startDay: today,
          startLimit: 5,
          quitDay: today.addDays(35),
        ),
      );

      final stats = ProgressCalculator.periodStats(
        range: week,
        logs: const [],
        boundary: boundary,
        history: replanned,
        today: today,
      );

      // Oct 14 and 15 at 9, Oct 16 to 18 at 5.
      expect(stats.allowed, 9 + 9 + 5 + 5 + 5);
      expect(stats.allowedByToday, 9 + 9 + 5);
    });

    test('period before the plan', () {
      final stats = ProgressCalculator.periodStats(
        range: PeriodRange.weekOf(LogicalDay(2026, 10, 5)),
        // Back-filled logs before the plan do not count.
        logs: logsOn(LogicalDay(2026, 10, 6), 3),
        boundary: boundary,
        history: history,
        today: today,
      );

      expect(stats.logged, 0);
      expect(stats.allowed, 0);
      expect(stats.allowedByToday, 0);
      expect(stats.avgPerDay, isNull);
      expect(stats.daysOver, 0);
      expect(stats.daysOnTrack, 0);
    });

    test('plan starting tomorrow has no tracked days yet', () {
      final later = PlanHistory([
        ReductionPlan(
          startDay: today.addDays(1),
          startLimit: 9,
          quitDay: today.addDays(1 + 63),
        ),
      ]);

      final stats = ProgressCalculator.periodStats(
        range: week,
        logs: logsOn(today, 2),
        boundary: boundary,
        history: later,
        today: today,
      );

      expect(stats.logged, 0);
      expect(stats.allowed, 18);
      expect(stats.allowedByToday, 0);
      expect(stats.avgPerDay, isNull);
      expect(stats.daysOnTrack, 0);
    });
  });
}

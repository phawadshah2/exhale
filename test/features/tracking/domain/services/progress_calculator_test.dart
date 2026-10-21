import 'package:exhale/core/domain/time/day_boundary.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/tracking/domain/entities/daily_progress.dart';
import 'package:exhale/features/tracking/domain/entities/habit_log.dart';
import 'package:exhale/features/tracking/domain/entities/period_range.dart';
import 'package:exhale/features/tracking/domain/entities/period_summary.dart';
import 'package:exhale/features/tracking/domain/services/progress_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Plan starts Wed 14 Oct 2026 at 9/day.
  final start = LogicalDay(2026, 10, 14);
  final history = PlanHistory([
    ReductionPlan(
      startDay: start,
      startLimit: 9,
      quitDay: start.addDays(9 * 7),
    ),
  ]);
  const boundary = DayBoundary();
  var nextId = 1;

  List<HabitLog> logsOn(LogicalDay day, int count) => [
    for (var i = 0; i < count; i++)
      HabitLog(
        id: nextId++,
        loggedAt: DateTime(day.year, day.month, day.day, 9 + i),
        habitKind: HabitKind.smoking,
      ),
  ];

  group('PeriodRange', () {
    test('week is Monday to Sunday', () {
      final week = PeriodRange.weekOf(LogicalDay(2026, 10, 16));

      expect(week.from, LogicalDay(2026, 10, 12));
      expect(week.to, LogicalDay(2026, 10, 18));
      expect(week.days, hasLength(7));
    });

    test('month covers every day of the month', () {
      final month = PeriodRange.monthOf(LogicalDay(2026, 2, 10));

      expect(month.from, LogicalDay(2026, 2, 1));
      expect(month.to, LogicalDay(2026, 2, 28));
      expect(month.length, 28);
    });
  });

  group('summarize', () {
    final today = LogicalDay(2026, 10, 16);
    final summary = ProgressCalculator.summarize(
      range: PeriodRange.weekOf(today),
      logs: [
        ...logsOn(start, 7),
        ...logsOn(start.addDays(1), 11),
        ...logsOn(today, 4),
      ],
      boundary: boundary,
      history: history,
      today: today,
    );

    test('marks days before the plan, tracked days and future days', () {
      expect(summary.slots.map((s) => s.kind), [
        DaySlotKind.beforePlan,
        DaySlotKind.beforePlan,
        DaySlotKind.tracked,
        DaySlotKind.tracked,
        DaySlotKind.tracked,
        DaySlotKind.future,
        DaySlotKind.future,
      ]);
      expect(summary.slots[4].isToday, isTrue);
      expect(summary.slots[5].progress, isNull);
      expect(summary.slots[5].limit, 9);
      expect(summary.slots.first.limit, isNull);
    });

    test('summarises tracked days only', () {
      expect(summary.averagePerDay, closeTo(22 / 3, 1e-9));
      expect(summary.daysOver, 1);
      expect(summary.daysWithin, 2);
      expect(summary.peak, 11);
    });

    test('has no average before anything is tracked', () {
      final early = ProgressCalculator.summarize(
        range: PeriodRange.weekOf(LogicalDay(2026, 10, 5)),
        logs: const [],
        boundary: boundary,
        history: history,
        today: today,
      );

      expect(early.averagePerDay, isNull);
      expect(
        early.slots.every((s) => s.kind == DaySlotKind.beforePlan),
        isTrue,
      );
    });
  });

  group('homeStats', () {
    List<DailyProgress> days(List<int> counts) => [
      for (var i = 0; i < counts.length; i++)
        DailyProgress(
          day: start.addDays(i),
          count: counts[i],
          limit: history.limitOn(start.addDays(i)),
        ),
    ];

    test('first day: nothing completed yet', () {
      final stats = ProgressCalculator.homeStats(
        days: days([0]),
        history: history,
        today: start,
        unitPriceCents: 72.5,
      );

      expect(stats.dayNumber, 1);
      expect(stats.streakDays, 1);
      expect(stats.recentAverage, isNull);
      expect(stats.changeFromBaseline, isNull);
      expect(stats.avoided, 0);
      expect(stats.moneySavedCents, 0);
    });

    test('streak counts back from today until an over-limit day', () {
      final stats = ProgressCalculator.homeStats(
        days: days([5, 12, 6, 7, 3]),
        history: history,
        today: start.addDays(4),
        unitPriceCents: null,
      );

      expect(stats.dayNumber, 5);
      expect(stats.streakDays, 3);
    });

    test('an over-limit today ends the streak', () {
      final stats = ProgressCalculator.homeStats(
        days: days([5, 6, 10]),
        history: history,
        today: start.addDays(2),
        unitPriceCents: null,
      );

      expect(stats.streakDays, 0);
    });

    test('average and avoided use completed days only', () {
      final stats = ProgressCalculator.homeStats(
        days: days([6, 6, 6, 1]),
        history: history,
        today: start.addDays(3),
        unitPriceCents: 50,
      );

      expect(stats.recentAverage, 6);
      expect(stats.changeFromBaseline, closeTo(-1 / 3, 1e-9));
      expect(stats.avoided, 9);
      expect(stats.moneySavedCents, 450);
    });

    test('average looks at the last 7 completed days', () {
      final stats = ProgressCalculator.homeStats(
        days: days([9, 9, 2, 2, 2, 2, 2, 2, 2, 0]),
        history: history,
        today: start.addDays(9),
        unitPriceCents: null,
      );

      expect(stats.recentAverage, 2);
    });

    test('smoking above baseline never shows negative avoided', () {
      final stats = ProgressCalculator.homeStats(
        days: days([15, 15, 0]),
        history: history,
        today: start.addDays(2),
        unitPriceCents: 50,
      );

      expect(stats.avoided, 0);
      expect(stats.changeFromBaseline, closeTo(6 / 9, 1e-9));
    });
  });
}

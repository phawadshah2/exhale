import 'package:exhale/core/domain/time/day_boundary.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/tracking/domain/entities/all_time_series.dart';
import 'package:exhale/features/tracking/domain/entities/habit_log.dart';
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
  // Long enough to cross the weekly threshold.
  final longHistory = PlanHistory([
    ReductionPlan(startDay: start, startLimit: 9, quitDay: start.addDays(300)),
  ]);
  const boundary = DayBoundary();
  var nextId = 1;

  List<HabitLog> logsOn(LogicalDay day, int count) => [
    for (var i = 0; i < count; i++)
      HabitLog(
        id: nextId++,
        loggedAt: DateTime(day.year, day.month, day.day, 9 + i),
        habitId: 1,
      ),
  ];

  AllTimeSeries seriesFor({
    required LogicalDay today,
    Iterable<HabitLog> logs = const [],
    PlanHistory? plan,
  }) => ProgressCalculator.allTime(
    logs: logs,
    boundary: boundary,
    history: plan ?? history,
    today: today,
  );

  group('allTime', () {
    test('counts run start to today and limits run start to quit day', () {
      final today = LogicalDay(2026, 10, 16);
      final series = seriesFor(
        today: today,
        logs: [...logsOn(start, 6), ...logsOn(today, 4)],
      );

      expect(series.start, start);
      expect(series.today, today);
      expect(series.end, LogicalDay(2026, 12, 16));
      expect(series.counts, [6, 0, 4]);
      expect(series.limits, hasLength(64));
      expect(series.limits.first, 9);
      expect(series.limits.last, 0);
      expect(series.average7, isNull);
      expect(series.weekly, isFalse);
    });

    test('end extends to today after the quit date', () {
      final today = LogicalDay(2026, 12, 20);
      final series = seriesFor(today: today);

      expect(series.end, today);
      expect(series.counts, hasLength(68));
      expect(series.limits, hasLength(68));
      expect(series.limits.last, 0);
    });

    test('logs before the plan and at 01:30 land on the right day', () {
      final today = LogicalDay(2026, 10, 17);
      final series = seriesFor(
        today: today,
        logs: [
          ...logsOn(start.addDays(-2), 5),
          // Sat 17 Oct 01:30 belongs to Fri 16 Oct.
          HabitLog(
            id: nextId++,
            habitId: 1,
            loggedAt: DateTime(2026, 10, 17, 1, 30),
          ),
        ],
      );

      expect(series.counts, [0, 0, 1, 0]);
    });

    test('switches to a 7-day average from 14 days', () {
      LogicalDay dayIndex(int i) => start.addDays(i);
      List<HabitLog> fourteenDays() => [
        for (var i = 0; i < 7; i++) ...logsOn(dayIndex(i), 6),
        for (var i = 7; i < 14; i++) ...logsOn(dayIndex(i), 3),
      ];

      final thirteen = seriesFor(today: dayIndex(12), logs: fourteenDays());
      final fourteen = seriesFor(today: dayIndex(13), logs: fourteenDays());

      expect(thirteen.average7, isNull);
      final average = fourteen.average7!;
      expect(average, hasLength(fourteen.counts.length));
      // Days 3 to 9: four at 6 and three at 3.
      expect(average[9], closeTo(33 / 7, 1e-9));
      expect(average.last, closeTo(3, 1e-9));
    });

    test('is daily up to 180 days and weekly beyond', () {
      final daily = seriesFor(today: start.addDays(179), plan: longHistory);
      final weekly = seriesFor(today: start.addDays(180), plan: longHistory);

      expect(daily.weekly, isFalse);
      expect(daily.counts, hasLength(180));
      expect(weekly.weekly, isTrue);
    });

    test('over 180 days, counts are weekly sums plotted once per week', () {
      final today = start.addDays(200);
      final series = seriesFor(
        today: today,
        plan: longHistory,
        logs: [for (var i = 0; i < 14; i++) ...logsOn(start.addDays(i), 1)],
      );

      expect(series.weekly, isTrue);
      // 201 days of counts and 301 days of limits, in blocks of 7 from day 1.
      expect(series.counts, hasLength(29));
      expect(series.limits, hasLength(43));
      expect(series.counts[0], 7);
      expect(series.counts[1], 7);
      expect(series.counts[2], 0);
      expect(series.limits[0], 7 * 9);
    });
  });
}

import 'package:exhale/core/domain/time/day_boundary.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/tracking/domain/entities/daily_progress.dart';
import 'package:exhale/features/tracking/domain/entities/smoke_log.dart';
import 'package:exhale/features/tracking/domain/services/daily_progress_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final oct15 = LogicalDay(2026, 10, 15);
  final history = PlanHistory([
    ReductionPlan(
      startDay: oct15,
      startLimit: 9,
      quitDay: oct15.addDays(9 * 7),
    ),
  ]);
  var nextId = 1;

  SmokeLog log(DateTime at) => SmokeLog(id: nextId++, loggedAt: at);

  test('one entry per day, including empty days', () {
    final result = buildDailyProgress(
      logs: [
        log(DateTime(2026, 10, 15, 9)),
        log(DateTime(2026, 10, 15, 13)),
        log(DateTime(2026, 10, 17, 8)),
      ],
      boundary: const DayBoundary(),
      history: history,
      from: oct15,
      to: oct15.addDays(2),
    );

    expect(result, [
      DailyProgress(day: oct15, count: 2, limit: 9),
      DailyProgress(day: oct15.addDays(1), count: 0, limit: 9),
      DailyProgress(day: oct15.addDays(2), count: 1, limit: 9),
    ]);
  });

  test('late-night logs count toward the previous day', () {
    final result = buildDailyProgress(
      logs: [log(DateTime(2026, 10, 16, 1, 30))],
      boundary: const DayBoundary(),
      history: history,
      from: oct15,
      to: oct15.addDays(1),
    );

    expect(result.map((p) => p.count), [1, 0]);
  });

  test('each day uses the limit in force that day', () {
    final result = buildDailyProgress(
      logs: const [],
      boundary: const DayBoundary(),
      history: history,
      from: oct15.addDays(5),
      to: oct15.addDays(8),
    );

    expect(result.map((p) => p.limit), [9, 9, 8, 8]);
  });

  test('ignores logs outside the range', () {
    final result = buildDailyProgress(
      logs: [log(DateTime(2026, 11, 1, 12))],
      boundary: const DayBoundary(),
      history: history,
      from: oct15,
      to: oct15,
    );

    expect(result.single.count, 0);
  });

  test('an inverted range is empty', () {
    expect(
      buildDailyProgress(
        logs: const [],
        boundary: const DayBoundary(),
        history: history,
        from: oct15,
        to: oct15.addDays(-1),
      ),
      isEmpty,
    );
  });
}

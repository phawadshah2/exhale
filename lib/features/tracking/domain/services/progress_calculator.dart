import 'dart:math' as math;

import 'package:exhale/core/domain/time/day_boundary.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/tracking/domain/entities/daily_progress.dart';
import 'package:exhale/features/tracking/domain/entities/habit_log.dart';
import 'package:exhale/features/tracking/domain/entities/home_stats.dart';
import 'package:exhale/features/tracking/domain/entities/limit_status.dart';
import 'package:exhale/features/tracking/domain/entities/period_range.dart';
import 'package:exhale/features/tracking/domain/entities/period_summary.dart';
import 'package:exhale/features/tracking/domain/services/daily_progress_builder.dart';

abstract final class ProgressCalculator {
  static const int recentWindowDays = 7;

  /// Chart slots for [range]; [logs] must cover the range.
  static PeriodSummary summarize({
    required PeriodRange range,
    required Iterable<HabitLog> logs,
    required DayBoundary boundary,
    required PlanHistory history,
    required LogicalDay today,
  }) {
    final firstDay = history.firstDay;
    final progress = {
      for (final p in buildDailyProgress(
        logs: logs,
        boundary: boundary,
        history: history,
        from: range.from,
        to: range.to.isAfter(today) ? today : range.to,
      ))
        p.day: p,
    };

    return PeriodSummary(
      range: range,
      slots: [
        for (final day in range.days)
          if (day.isBefore(firstDay))
            DaySlot(
              day: day,
              kind: DaySlotKind.beforePlan,
              isToday: day == today,
              beforePlanCount: progress[day]?.count,
            )
          else if (day.isAfter(today))
            DaySlot(
              day: day,
              kind: DaySlotKind.future,
              isToday: false,
              limit: history.limitOn(day),
            )
          else
            DaySlot(
              day: day,
              kind: DaySlotKind.tracked,
              isToday: day == today,
              progress: progress[day],
              limit: history.limitOn(day),
            ),
      ],
    );
  }

  /// [days] must be every plan day from the first through [today], in order.
  static HomeStats homeStats({
    required List<DailyProgress> days,
    required PlanHistory history,
    required LogicalDay today,
    required double? unitPriceCents,
  }) {
    final baseline = history.plans.first.startLimit;
    final completed = days.where((d) => d.day.isBefore(today)).toList();

    var streak = 0;
    for (final day in days.reversed) {
      if (day.status == LimitStatus.over) break;
      streak++;
    }

    final recent = completed.length > recentWindowDays
        ? completed.sublist(completed.length - recentWindowDays)
        : completed;
    final recentAverage = recent.isEmpty
        ? null
        : recent.fold<int>(0, (sum, d) => sum + d.count) / recent.length;

    final avoided = math.max(
      0,
      completed.fold<int>(0, (sum, d) => sum + baseline - d.count),
    );

    return HomeStats(
      dayNumber: math.max(1, today.daysSince(history.firstDay) + 1),
      streakDays: streak,
      baseline: baseline,
      recentAverage: recentAverage,
      avoided: avoided,
      moneySavedCents: unitPriceCents == null ? null : avoided * unitPriceCents,
    );
  }
}

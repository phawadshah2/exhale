import 'dart:math' as math;

import 'package:exhale/core/domain/time/day_boundary.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/tracking/domain/entities/all_time_series.dart';
import 'package:exhale/features/tracking/domain/entities/daily_progress.dart';
import 'package:exhale/features/tracking/domain/entities/habit_log.dart';
import 'package:exhale/features/tracking/domain/entities/home_stats.dart';
import 'package:exhale/features/tracking/domain/entities/limit_status.dart';
import 'package:exhale/features/tracking/domain/entities/period_range.dart';
import 'package:exhale/features/tracking/domain/entities/period_stats.dart';
import 'package:exhale/features/tracking/domain/entities/period_summary.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:exhale/features/tracking/domain/entities/trigger_breakdown.dart';
import 'package:exhale/features/tracking/domain/services/daily_progress_builder.dart';

abstract final class ProgressCalculator {
  static const int recentWindowDays = 7;
  static const int averageAfterDays = 14;
  static const int weeklyAfterDays = 180;

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

  /// Totals for [range], counting plan days only. Each day is held to the
  /// limit of the plan in force that day.
  static PeriodStats periodStats({
    required PeriodRange range,
    required Iterable<HabitLog> logs,
    required DayBoundary boundary,
    required PlanHistory history,
    required LogicalDay today,
  }) {
    final first = _later(range.from, history.firstDay);

    var allowed = 0;
    for (var day = first; !day.isAfter(range.to); day = day.addDays(1)) {
      allowed += history.limitOn(day);
    }

    final tracked = buildDailyProgress(
      logs: logs,
      boundary: boundary,
      history: history,
      from: first,
      to: range.to.isAfter(today) ? today : range.to,
    );
    final logged = tracked.fold<int>(0, (sum, p) => sum + p.count);
    final over = tracked.where((p) => p.status == LimitStatus.over).length;

    return PeriodStats(
      logged: logged,
      allowed: allowed,
      allowedByToday: tracked.fold<int>(0, (sum, p) => sum + p.limit),
      avgPerDay: tracked.isEmpty ? null : logged / tracked.length,
      daysOver: over,
      daysOnTrack: tracked.length - over,
    );
  }

  static TriggerBreakdown triggerBreakdown(Iterable<HabitLog> logs) {
    final counts = <Trigger, int>{};
    var total = 0;
    var noTrigger = 0;
    for (final log in logs) {
      total++;
      final trigger = log.trigger;
      if (trigger == null) {
        noTrigger++;
      } else {
        counts[trigger] = (counts[trigger] ?? 0) + 1;
      }
    }

    final ranked = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.index.compareTo(b.key.index);
      });

    return TriggerBreakdown(
      shares: [
        for (final entry in ranked)
          TriggerShare(
            trigger: entry.key,
            count: entry.value,
            fraction: entry.value / total,
          ),
      ],
      noTrigger: noTrigger,
      total: total,
    );
  }

  /// Daily counts and limits since the first plan. Past
  /// [weeklyAfterDays] days both are summed in 7-day blocks.
  static AllTimeSeries allTime({
    required Iterable<HabitLog> logs,
    required DayBoundary boundary,
    required PlanHistory history,
    required LogicalDay today,
  }) {
    final start = history.firstDay;
    final end = _later(history.current.quitDay, today);

    final counts = [
      for (final p in buildDailyProgress(
        logs: logs,
        boundary: boundary,
        history: history,
        from: start,
        to: today,
      ))
        p.count,
    ];
    final limits = [
      for (var day = start; !day.isAfter(end); day = day.addDays(1))
        history.limitOn(day),
    ];

    final weekly = counts.length > weeklyAfterDays;
    List<double>? average7;
    if (!weekly && counts.length >= averageAfterDays) {
      average7 = [
        for (var i = 0; i < counts.length; i++)
          _sum(counts, math.max(0, i - 6), i + 1) / (math.min(i, 6) + 1),
      ];
    }

    return AllTimeSeries(
      start: start,
      end: end,
      today: today,
      counts: weekly ? _weekly(counts) : counts,
      average7: average7,
      limits: weekly ? _weekly(limits) : limits,
      weekly: weekly,
    );
  }

  static LogicalDay _later(LogicalDay a, LogicalDay b) => a.isAfter(b) ? a : b;

  static int _sum(List<int> values, int from, int to) =>
      values.sublist(from, to).fold(0, (sum, v) => sum + v);

  static List<int> _weekly(List<int> daily) => [
    for (var i = 0; i < daily.length; i += 7)
      _sum(daily, i, math.min(i + 7, daily.length)),
  ];

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

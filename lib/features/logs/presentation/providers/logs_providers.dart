import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/tracking/domain/entities/daily_progress.dart';
import 'package:exhale/features/tracking/domain/entities/habit_log.dart';
import 'package:exhale/features/tracking/domain/entities/period_range.dart';
import 'package:exhale/features/tracking/domain/entities/period_stats.dart';
import 'package:exhale/features/tracking/domain/entities/trigger_breakdown.dart';
import 'package:exhale/features/tracking/domain/services/progress_calculator.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:meta/meta.dart';

typedef LogsScope = ({int habitId, PeriodRange range});

/// One day of the Logs list.
@immutable
class LogsDay {
  const LogsDay({required this.day, required this.logs, required this.limit});

  final LogicalDay day;

  /// Newest first.
  final List<HabitLog> logs;

  /// Null before the habit's plan started.
  final int? limit;

  int get count => logs.length;

  DailyProgress? get progress => limit == null
      ? null
      : DailyProgress(day: day, count: count, limit: limit!);
}

@immutable
class LogsView {
  const LogsView({
    required this.stats,
    required this.breakdown,
    required this.days,
  });

  final PeriodStats stats;

  /// Plan days only, like [stats].
  final TriggerBreakdown breakdown;

  /// Newest first, today at the latest; plan days with no logs are kept,
  /// days before the plan only when they have logs.
  final List<LogsDay> days;
}

final ProviderFamily<LogsView?, LogsScope> logsViewProvider = Provider
    .autoDispose
    .family<LogsView?, LogsScope>((ref, scope) {
      final logs = ref.watch(logsInRangeProvider(scope)).value;
      final history = ref.watch(planHistoryProvider(scope.habitId)).value;
      if (logs == null || history == null) return null;
      final boundary = ref.watch(dayBoundaryProvider);
      final today = ref.watch(todayProvider);
      final range = scope.range;

      final byDay = <LogicalDay, List<HabitLog>>{};
      for (final log in logs.reversed) {
        byDay.putIfAbsent(boundary.dayOf(log.loggedAt), () => []).add(log);
      }

      final days = <LogsDay>[];
      final last = range.to.isAfter(today) ? today : range.to;
      for (var day = last; !day.isBefore(range.from); day = day.addDays(-1)) {
        final dayLogs = byDay[day] ?? const <HabitLog>[];
        final beforePlan = day.isBefore(history.firstDay);
        if (beforePlan && dayLogs.isEmpty) continue;
        days.add(
          LogsDay(
            day: day,
            logs: dayLogs,
            limit: beforePlan ? null : history.limitOn(day),
          ),
        );
      }

      return LogsView(
        stats: ProgressCalculator.periodStats(
          range: range,
          logs: logs,
          boundary: boundary,
          history: history,
          today: today,
        ),
        breakdown: ProgressCalculator.triggerBreakdown(
          logs.where(
            (log) => !boundary.dayOf(log.loggedAt).isBefore(history.firstDay),
          ),
        ),
        days: days,
      );
    });

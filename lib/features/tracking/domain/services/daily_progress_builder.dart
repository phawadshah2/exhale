import 'package:exhale/core/domain/time/day_boundary.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/tracking/domain/entities/daily_progress.dart';
import 'package:exhale/features/tracking/domain/entities/habit_log.dart';

/// One [DailyProgress] per day from [from] to [to] (both inclusive), with
/// each log counted on the logical day [boundary] assigns it to.
List<DailyProgress> buildDailyProgress({
  required Iterable<HabitLog> logs,
  required DayBoundary boundary,
  required PlanHistory history,
  required LogicalDay from,
  required LogicalDay to,
}) {
  if (to.isBefore(from)) return const [];

  final counts = <LogicalDay, int>{};
  for (final log in logs) {
    final day = boundary.dayOf(log.loggedAt);
    counts[day] = (counts[day] ?? 0) + 1;
  }

  return List.unmodifiable([
    for (var day = from; !day.isAfter(to); day = day.addDays(1))
      DailyProgress(
        day: day,
        count: counts[day] ?? 0,
        limit: history.limitOn(day),
      ),
  ]);
}

import 'package:exhale/core/domain/time/day_boundary.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/domain/entities/plan_hold.dart';
import 'package:exhale/features/plan/domain/entities/plan_stage.dart';
import 'package:exhale/features/plan/domain/entities/stage_check.dart';
import 'package:exhale/features/tracking/domain/entities/daily_progress.dart';
import 'package:exhale/features/tracking/domain/entities/habit_log.dart';
import 'package:exhale/features/tracking/domain/services/daily_progress_builder.dart';
import 'package:meta/meta.dart';

/// What one check found, ready to be stored.
@immutable
class StageCheckResult {
  const StageCheckResult({
    required this.outcome,
    required this.windowEndDay,
    required this.logged,
    required this.allowed,
    required this.overDays,
    this.hold,
    this.closesWaitingHold = false,
  });

  final StageOutcome outcome;
  final LogicalDay windowEndDay;

  /// Logs in the window.
  final int logged;

  /// The sum of the window's daily limits.
  final int allowed;

  /// Days in the window above that day's limit.
  final int overDays;

  /// The pause to store with a [StageOutcome.hold].
  final PlanHold? hold;

  /// True when a hold card from an earlier window still waits, and this
  /// check answers it.
  final bool closesWaitingHold;
}

/// The stage check of Stages spec section 2, as a pure function.
abstract final class StageChecks {
  static const int windowDays = 7;
  static const int maxLateDays = 2;
  static const int nearStartDays = 14;

  /// Share of the first limit, in tenths, the 14-day average must reach.
  static const int _nearStartTenths = 9;

  /// The check due on [today], or null when none is.
  ///
  /// [checks] may hold other plans' checks and come in any order; only the
  /// current plan's are read.
  static StageCheckResult? evaluate({
    required PlanHistory history,
    required List<HabitLog> logs,
    required DayBoundary boundary,
    required List<StageCheck> checks,
    required LogicalDay today,
  }) {
    final plan = history.current;
    final stage = _latestEndedStage(plan.stages, today);
    if (stage == null) return null;

    final own = [...checks.where((c) => c.planStartDay == plan.startDay)]
      ..sort((a, b) => b.windowEndDay.compareTo(a.windowEndDay));

    final waitingCard = own.any(
      (c) =>
          c.answeredAt == null &&
          (c.outcome == StageOutcome.review ||
              c.outcome == StageOutcome.reassess),
    );
    if (waitingCard) return null;

    final end = stage.endDay;
    if (end.daysSince(plan.startDay) + 1 < windowDays) return null;
    if (own.isNotEmpty && end.daysSince(own.first.windowEndDay) < windowDays) {
      return null;
    }

    if (today.daysSince(end) > maxLateDays) {
      return StageCheckResult(
        outcome: StageOutcome.skipped,
        windowEndDay: end,
        logged: 0,
        allowed: 0,
        overDays: 0,
      );
    }

    final window = buildDailyProgress(
      logs: logs,
      boundary: boundary,
      history: history,
      from: end.addDays(1 - windowDays),
      to: end,
    );
    final logged = _sum(window, (d) => d.count);
    final allowed = _sum(window, (d) => d.limit);
    final overDays = window.where((d) => d.count > d.limit).length;
    final failed = logged > allowed && overDays >= 2;

    final waitingHold = own.any(
      (c) => c.outcome == StageOutcome.hold && c.answeredAt == null,
    );

    StageCheckResult result(StageOutcome outcome, {PlanHold? hold}) =>
        StageCheckResult(
          outcome: outcome,
          windowEndDay: end,
          logged: logged,
          allowed: allowed,
          overDays: overDays,
          hold: hold,
          closesWaitingHold: waitingHold,
        );

    if (!failed) return result(StageOutcome.passed);
    if (_isNearStart(history, logs, boundary, end)) {
      return result(StageOutcome.reassess);
    }
    if (_holdStreak(own) == 0) {
      return result(
        StageOutcome.hold,
        hold: PlanHold(startDay: end.addDays(1)),
      );
    }
    return result(StageOutcome.review);
  }

  static PlanStage? _latestEndedStage(List<PlanStage> stages, LogicalDay day) {
    PlanStage? latest;
    for (final stage in stages) {
      if (stage.endDay.isBefore(day)) latest = stage;
    }
    return latest;
  }

  /// Failed checks in a row that ended in a hold, newest first, up to the
  /// first check of any other kind.
  static int _holdStreak(List<StageCheck> newestFirst) {
    var streak = 0;
    for (final check in newestFirst) {
      if (check.outcome != StageOutcome.hold) break;
      streak++;
    }
    return streak;
  }

  /// The plan began at least 14 days before [windowEnd] and the 14 days
  /// ending there averaged at least 90% of the first plan's limit.
  static bool _isNearStart(
    PlanHistory history,
    List<HabitLog> logs,
    DayBoundary boundary,
    LogicalDay windowEnd,
  ) {
    if (windowEnd.daysSince(history.firstDay) < nearStartDays) return false;
    final days = buildDailyProgress(
      logs: logs,
      boundary: boundary,
      history: history,
      from: windowEnd.addDays(1 - nearStartDays),
      to: windowEnd,
    );
    final total = _sum(days, (d) => d.count);
    return total * 10 >=
        _nearStartTenths * nearStartDays * history.plans.first.startLimit;
  }

  static int _sum(List<DailyProgress> days, int Function(DailyProgress) of) =>
      days.fold(0, (sum, day) => sum + of(day));
}

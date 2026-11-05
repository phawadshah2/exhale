import 'package:exhale/core/domain/time/day_boundary.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/plan/domain/entities/stage_check.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/tracking/domain/entities/habit_log.dart';
import 'package:exhale/features/tracking/domain/entities/trigger_breakdown.dart';
import 'package:exhale/features/tracking/domain/services/daily_progress_builder.dart';
import 'package:exhale/features/tracking/domain/services/progress_calculator.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:meta/meta.dart';

/// The card a stage check leaves on Home until it is answered.
@immutable
sealed class StageCard {
  const StageCard({required this.planStartDay, required this.windowEndDay});

  /// Names the plan and the window of the check the card answers.
  final LogicalDay planStartDay;
  final LogicalDay windowEndDay;
}

/// Seven more days at [limit] (Stages spec 5.1).
class HoldCardData extends StageCard {
  const HoldCardData({
    required super.planStartDay,
    required super.windowEndDay,
    required this.logged,
    required this.allowed,
    required this.limit,
    required this.nextLimit,
    required this.nextDrop,
    required this.wasNextDrop,
    required this.quitDay,
    required this.wasQuitDay,
    required this.keepLimit,
    required this.holdStart,
    required this.isLateOpen,
    required this.offersKeep,
  });

  /// The window's logs and daily limits added up.
  final int logged;
  final int allowed;

  /// The limit that stays for the extra days.
  final int limit;

  /// The limit after them; 0 on the last stage.
  final int nextLimit;
  final LogicalDay nextDrop;
  final LogicalDay wasNextDrop;
  final LogicalDay quitDay;
  final LogicalDay wasQuitDay;

  /// Today's limit if the hold is taken back.
  final int keepLimit;
  final LogicalDay holdStart;

  /// The check ran after the stage's day was over, so days went unseen.
  final bool isLateOpen;

  /// Only on the day of the check.
  final bool offersKeep;

  @override
  bool operator ==(Object other) =>
      other is HoldCardData &&
      other.planStartDay == planStartDay &&
      other.windowEndDay == windowEndDay &&
      other.logged == logged &&
      other.allowed == allowed &&
      other.limit == limit &&
      other.nextLimit == nextLimit &&
      other.nextDrop == nextDrop &&
      other.wasNextDrop == wasNextDrop &&
      other.quitDay == quitDay &&
      other.wasQuitDay == wasQuitDay &&
      other.keepLimit == keepLimit &&
      other.holdStart == holdStart &&
      other.isLateOpen == isLateOpen &&
      other.offersKeep == offersKeep;

  @override
  int get hashCode => Object.hash(
    planStartDay,
    windowEndDay,
    logged,
    allowed,
    limit,
    nextLimit,
    nextDrop,
    wasNextDrop,
    quitDay,
    wasQuitDay,
    keepLimit,
    holdStart,
    isLateOpen,
    offersKeep,
  );
}

class ReviewCardData extends StageCard {
  const ReviewCardData({
    required super.planStartDay,
    required super.windowEndDay,
    required this.earlierWindowEndDay,
    required this.limit,
  });

  /// The end of the hold check's window, the first of the two failed weeks.
  final LogicalDay earlierWindowEndDay;

  /// The checked stage's limit; null when the two failed weeks had more than
  /// one.
  final int? limit;

  @override
  bool operator ==(Object other) =>
      other is ReviewCardData &&
      other.planStartDay == planStartDay &&
      other.windowEndDay == windowEndDay &&
      other.earlierWindowEndDay == earlierWindowEndDay &&
      other.limit == limit;

  @override
  int get hashCode =>
      Object.hash(planStartDay, windowEndDay, earlierWindowEndDay, limit);
}

class ReassessCardData extends StageCard {
  const ReassessCardData({
    required super.planStartDay,
    required super.windowEndDay,
    required this.average,
  });

  /// The 14-day average, rounded up.
  final int average;

  @override
  bool operator ==(Object other) =>
      other is ReassessCardData &&
      other.planStartDay == planStartDay &&
      other.windowEndDay == windowEndDay &&
      other.average == average;

  @override
  int get hashCode => Object.hash(planStartDay, windowEndDay, average);
}

/// Two 7-day windows ending on `windowEnd` and `earlierEnd`. With
/// `earlierEnd == windowEnd.addDays(-7)` they are 14 days in a row.
typedef StageWindow = ({
  int habitId,
  LogicalDay earlierEnd,
  LogicalDay windowEnd,
});

bool _inWindow(StageWindow key, LogicalDay day) =>
    _inWeek(day, key.windowEnd) || _inWeek(day, key.earlierEnd);

bool _inWeek(LogicalDay day, LogicalDay end) =>
    !day.isAfter(end) && !day.isBefore(end.addDays(-6));

/// The logs from the first day of the earlier window to `windowEnd`, gap
/// included.
final StreamProviderFamily<List<HabitLog>, StageWindow>
stageWindowLogsProvider = StreamProvider.family<List<HabitLog>, StageWindow>((
  ref,
  key,
) {
  final boundary = ref.watch(dayBoundaryProvider);
  return ref
      .watch(habitLogRepositoryProvider)
      .watchLogs(
        habitId: key.habitId,
        from: boundary.startOf(key.earlierEnd.addDays(-6)),
        to: boundary.endOf(key.windowEnd),
      );
});

/// The 14 days of a [StageWindow], added up.
@immutable
class StageWindowStats {
  const StageWindowStats({
    required this.logged,
    required this.allowed,
    required this.topTriggers,
  });

  final int logged;
  final int allowed;

  /// The three most used triggers; empty when no log has one.
  final List<TriggerShare> topTriggers;

  /// Logs a day, rounded up.
  int get average => (logged + 13) ~/ 14;
}

final ProviderFamily<StageWindowStats?, StageWindow> stageWindowStatsProvider =
    Provider.family<StageWindowStats?, StageWindow>((ref, key) {
      final history = ref.watch(planHistoryProvider(key.habitId)).value;
      final all = ref.watch(stageWindowLogsProvider(key)).value;
      if (history == null || all == null) return null;
      final boundary = ref.watch(dayBoundaryProvider);
      final logs = [
        for (final log in all)
          if (_inWindow(key, boundary.dayOf(log.loggedAt))) log,
      ];
      final days = buildDailyProgress(
        logs: logs,
        boundary: boundary,
        history: history,
        from: key.earlierEnd.addDays(-6),
        to: key.windowEnd,
      ).where((day) => _inWindow(key, day.day));
      return StageWindowStats(
        logged: days.fold<int>(0, (sum, day) => sum + day.count),
        allowed: days.fold<int>(0, (sum, day) => sum + day.limit),
        topTriggers: ProgressCalculator.triggerBreakdown(logs).top(3),
      );
    });

/// The unanswered hold, review or reassess card of the habit's **current**
/// plan; null when there is none. A replanned plan starts with no cards.
final ProviderFamily<StageCard?, int> stageCardProvider =
    Provider.family<StageCard?, int>((ref, habitId) {
      final history = ref.watch(planHistoryProvider(habitId)).value;
      final checks = ref.watch(stageChecksProvider(habitId)).value;
      if (history == null || checks == null) return null;

      final plan = history.current;
      final waiting = [
        ...checks.where(
          (c) =>
              c.planStartDay == plan.startDay &&
              c.answeredAt == null &&
              (c.outcome == StageOutcome.hold ||
                  c.outcome == StageOutcome.review ||
                  c.outcome == StageOutcome.reassess),
        ),
      ]..sort((a, b) => b.windowEndDay.compareTo(a.windowEndDay));
      if (waiting.isEmpty) return null;
      final check = waiting.first;

      // A review covers its own window and the hold check's before it, the
      // newest earlier check of the plan; the rest cover 14 days in a row.
      final earlier = check.outcome == StageOutcome.review
          ? checks
                .where(
                  (c) =>
                      c.planStartDay == plan.startDay &&
                      c.windowEndDay.isBefore(check.windowEndDay),
                )
                .map((c) => c.windowEndDay)
                .fold<LogicalDay?>(
                  null,
                  (newest, day) =>
                      newest == null || day.isAfter(newest) ? day : newest,
                )
          : null;
      final window = (
        habitId: habitId,
        earlierEnd: earlier ?? check.windowEndDay.addDays(-7),
        windowEnd: check.windowEndDay,
      );
      final logs = ref.watch(stageWindowLogsProvider(window)).value;
      if (logs == null) return null;

      final boundary = ref.watch(dayBoundaryProvider);
      final today = ref.watch(todayProvider);
      return _build(check, window, history, plan, logs, boundary, today);
    });

StageCard? _build(
  StageCheck check,
  StageWindow window,
  PlanHistory history,
  ReductionPlan plan,
  List<HabitLog> logs,
  DayBoundary boundary,
  LogicalDay today,
) {
  final end = check.windowEndDay;
  final fortnight = buildDailyProgress(
    logs: logs,
    boundary: boundary,
    history: history,
    from: window.earlierEnd.addDays(-6),
    to: end,
  ).where((day) => _inWindow(window, day.day)).toList();

  switch (check.outcome) {
    case StageOutcome.review:
      final limits = {for (final day in fortnight) day.limit};
      return ReviewCardData(
        planStartDay: check.planStartDay,
        windowEndDay: end,
        earlierWindowEndDay: window.earlierEnd,
        limit: limits.length == 1 ? limits.single : null,
      );
    case StageOutcome.reassess:
      final total = fortnight.fold<int>(0, (sum, day) => sum + day.count);
      return ReassessCardData(
        planStartDay: check.planStartDay,
        windowEndDay: end,
        average: (total + 13) ~/ 14,
      );
    case StageOutcome.hold:
      final holdStart = end.addDays(1);
      final hold = plan.holds.where((h) => h.startDay == holdStart).firstOrNull;
      final held = plan.stageOn(end);
      if (hold == null || held == null) return null;
      final week = fortnight.skip(7);
      final nextDrop = held.endDay.addDays(1);
      final withoutHold = ReductionPlan(
        startDay: plan.startDay,
        startLimit: plan.startLimit,
        quitDay: plan.agreedQuitDay,
        holds: [
          for (final other in plan.holds)
            if (other != hold) other,
        ],
      );
      return HoldCardData(
        planStartDay: check.planStartDay,
        windowEndDay: end,
        logged: week.fold<int>(0, (sum, day) => sum + day.count),
        allowed: week.fold<int>(0, (sum, day) => sum + day.limit),
        limit: held.limit,
        nextLimit: plan.limitOn(nextDrop),
        nextDrop: nextDrop,
        wasNextDrop: holdStart,
        quitDay: plan.quitDay,
        wasQuitDay: plan.quitDay.addDays(-hold.days),
        keepLimit: withoutHold.limitOn(today),
        holdStart: holdStart,
        isLateOpen: check.checkDay.isAfter(holdStart),
        offersKeep: today == check.checkDay,
      );
    case StageOutcome.passed:
    case StageOutcome.skipped:
      return null;
  }
}

import 'dart:math' as math;

import 'package:exhale/core/domain/time/day_boundary.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/habit/domain/entities/price_history.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/domain/entities/plan_stage.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/tracking/domain/entities/daily_progress.dart';
import 'package:exhale/features/tracking/domain/entities/habit_log.dart';
import 'package:exhale/features/tracking/domain/entities/limit_status.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:exhale/features/tracking/domain/services/daily_progress_builder.dart';
import 'package:exhale/features/tracking/domain/services/progress_calculator.dart';
import 'package:meta/meta.dart';

/// Which line a stage row closes with.
enum StageNote {
  best,
  easyOne,
  noneOver,
  oneOver,
  someOver,
  last,
  oneFewer,
  halfway,
  written,
}

/// "The whole plan": every plan the habit has run, with what each figure is
/// out of. Money is null when the habit has no current price.
@immutable
class PlanTotals {
  const PlanTotals({
    required this.used,
    required this.usedOf,
    required this.avoided,
    required this.avoidedOf,
    required this.kept,
    required this.keptOf,
    required this.withoutPlanUnits,
    required this.savedCents,
    required this.savedOfCents,
    required this.withoutPlanCents,
  });

  final int used;
  final int usedOf;
  final int avoided;
  final int avoidedOf;
  final int kept;
  final int keptOf;
  final int withoutPlanUnits;
  final double? savedCents;
  final double? savedOfCents;
  final double? withoutPlanCents;
}

/// One stage as it went, or will go. A stage cut off by a replan counts only
/// the days it ran.
@immutable
class StageReport {
  const StageReport({
    required this.stage,
    required this.lastDay,
    required this.days,
    required this.used,
    required this.allowed,
    required this.daysOver,
    required this.average,
    required this.savedCents,
    required this.toSaveCents,
    required this.toAvoid,
    required this.mostly,
    required this.note,
    required this.daily,
  });

  final PlanStage stage;
  final LogicalDay lastDay;
  final int days;
  final int used;
  final int allowed;
  final int daysOver;
  final double average;

  /// Over finished days and not clamped, so stages sum to the total. Widgets
  /// show it as at least 0.
  final double? savedCents;
  final double? toSaveCents;

  /// Below the baseline over the whole stage, at least 0.
  final int toAvoid;
  final Trigger? mostly;
  final StageNote? note;

  /// Every day of the stage through today.
  final List<DailyProgress> daily;

  bool get isOverAllowed => used > allowed;

  StageReport withNote(StageNote note) => StageReport(
    stage: stage,
    lastDay: lastDay,
    days: days,
    used: used,
    allowed: allowed,
    daysOver: daysOver,
    average: average,
    savedCents: savedCents,
    toSaveCents: toSaveCents,
    toAvoid: toAvoid,
    mostly: mostly,
    note: note,
    daily: daily,
  );
}

/// Ended stages of one plan. [earlierUntil] is that plan's last day, or null
/// for the current plan.
@immutable
class StageGroup {
  const StageGroup({required this.earlierUntil, required this.stages});

  final LogicalDay? earlierUntil;
  final List<StageReport> stages;
}

@immutable
class PlanReport {
  const PlanReport({
    required this.totals,
    required this.behind,
    required this.current,
    required this.ahead,
    required this.behindSavedCents,
    required this.aheadToSaveCents,
    required this.stageCount,
    required this.quitReached,
    required this.quitDay,
  });

  factory PlanReport.build({
    required List<HabitLog> logs,
    required DayBoundary boundary,
    required PlanHistory history,
    required PriceHistory? prices,
    required LogicalDay today,
  }) {
    final tracked = buildDailyProgress(
      logs: logs,
      boundary: boundary,
      history: history,
      from: history.firstDay,
      to: today,
    );
    final logsByDay = <LogicalDay, List<HabitLog>>{};
    for (final log in logs) {
      (logsByDay[boundary.dayOf(log.loggedAt)] ??= []).add(log);
    }
    final builder = _StageBuilder(
      baseline: history.plans.first.startLimit,
      prices: prices,
      today: today,
      tracked: {for (final day in tracked) day.day: day},
      logs: logsByDay,
    );
    final plan = history.current;

    // Stages by plan, without their notes: the best of them needs them all.
    final ended = <List<StageReport>>[
      for (final (index, earlier) in history.plans.indexed.take(
        history.plans.length - 1,
      ))
        [
          for (final stage in earlier.stages)
            if (stage.startDay.isBefore(history.plans[index + 1].startDay))
              builder.report(
                stage,
                _earlier(
                  stage.endDay,
                  history.plans[index + 1].startDay.addDays(-1),
                ),
              ),
        ],
      [
        for (final stage in plan.stages)
          if (stage.endDay.isBefore(today)) builder.report(stage, stage.endDay),
      ],
    ];
    final best = _best(ended.expand((stages) => stages).toList());

    final behind = <StageGroup>[
      for (final (index, stages) in ended.indexed)
        if (stages.isNotEmpty)
          StageGroup(
            earlierUntil: index < ended.length - 1 ? stages.last.lastDay : null,
            stages: [
              for (final report in stages)
                report.withNote(
                  _behindNote(
                    report,
                    isBest: report == best,
                    isFirst: index == 0 && report.stage.number == 1,
                  ),
                ),
            ],
          ),
    ];

    final currentStage = plan.stageOn(today);
    final later = plan.stages.where((s) => s.startDay.isAfter(today)).toList();
    final ahead = [
      for (final (index, stage) in later.indexed)
        builder
            .report(stage, stage.endDay)
            .withNote(_aheadNote(stage, plan: plan, isNext: index == 0)),
    ];

    final hasPrice = prices?.currentUnitPriceCents != null;
    return PlanReport(
      totals: _totals(tracked, history, prices, today),
      behind: behind,
      current: currentStage == null
          ? null
          : builder.report(currentStage, currentStage.endDay),
      ahead: ahead,
      behindSavedCents: hasPrice
          ? _sum(behind.expand((g) => g.stages).map((s) => s.savedCents!))
          : null,
      aheadToSaveCents: hasPrice
          ? _sum(ahead.map((s) => s.toSaveCents!))
          : null,
      stageCount: plan.stageCount,
      quitReached: plan.isCompleteOn(today),
      quitDay: plan.quitDay,
    );
  }

  final PlanTotals totals;
  final List<StageGroup> behind;
  final StageReport? current;
  final List<StageReport> ahead;
  final double? behindSavedCents;
  final double? aheadToSaveCents;
  final int stageCount;
  final bool quitReached;
  final LogicalDay quitDay;

  /// The current plan's ended stages need naming once earlier plans sit above
  /// them.
  bool get showsThisPlanLabel =>
      behind.length > 1 && behind.last.earlierUntil == null;

  static PlanTotals _totals(
    List<DailyProgress> tracked,
    PlanHistory history,
    PriceHistory? prices,
    LogicalDay today,
  ) {
    final baseline = history.plans.first.startLimit;
    final current = prices?.currentUnitPriceCents;
    final lastPlanDay = history.current.quitDay.addDays(-1);
    final end = lastPlanDay.isAfter(today) ? lastPlanDay : today;

    var days = 0;
    var usedOf = 0;
    var avoidedOf = 0;
    var savedOf = 0.0;
    var without = 0.0;
    for (var day = history.firstDay; !day.isAfter(end); day = day.addDays(1)) {
      final limit = history.limitOn(day);
      days++;
      usedOf += limit;
      avoidedOf += baseline - limit;
      if (current != null) {
        final price = day.isAfter(today)
            ? current
            : prices!.unitPriceCentsOn(day) ?? 0;
        savedOf += (baseline - limit) * price;
        without += baseline * price;
      }
    }

    final stats = ProgressCalculator.homeStats(
      days: tracked,
      history: history,
      today: today,
      prices: prices,
    );
    final finished = tracked.where((d) => d.day.isBefore(today)).toList();
    return PlanTotals(
      used: tracked.fold(0, (sum, d) => sum + d.count),
      usedOf: usedOf,
      avoided: stats.avoided,
      avoidedOf: math.max(0, avoidedOf),
      kept: finished.where((d) => d.status != LimitStatus.over).length,
      keptOf: finished.length,
      withoutPlanUnits: baseline * days,
      savedCents: stats.moneySavedCents,
      savedOfCents: current == null ? null : math.max(0, savedOf),
      withoutPlanCents: current == null ? null : without,
    );
  }

  static LogicalDay _earlier(LogicalDay a, LogicalDay b) =>
      a.isBefore(b) ? a : b;

  static double _sum(Iterable<double> values) =>
      values.fold(0, (sum, value) => sum + value);

  /// The lowest share of its allowance, oldest first on a tie; none until two
  /// stages have ended.
  static StageReport? _best(List<StageReport> ended) {
    if (ended.length < 2) return null;
    return ended.reduce(
      (best, report) => report.used * best.allowed < best.used * report.allowed
          ? report
          : best,
    );
  }

  static StageNote _behindNote(
    StageReport report, {
    required bool isBest,
    required bool isFirst,
  }) {
    if (isBest) return StageNote.best;
    if (isFirst) return StageNote.easyOne;
    return switch (report.daysOver) {
      0 => StageNote.noneOver,
      1 => StageNote.oneOver,
      _ => StageNote.someOver,
    };
  }

  static StageNote _aheadNote(
    PlanStage stage, {
    required ReductionPlan plan,
    required bool isNext,
  }) {
    final index = stage.number - 1;
    if (index == plan.stages.length - 1) return StageNote.last;
    if (isNext &&
        index > 0 &&
        plan.stages[index - 1].limit - stage.limit == 1) {
      return StageNote.oneFewer;
    }
    final halfway = plan.stages
        .where((s) => s.limit * 2 <= plan.startLimit)
        .firstOrNull;
    return stage == halfway ? StageNote.halfway : StageNote.written;
  }
}

/// Reports one stage from a habit's days and logs.
class _StageBuilder {
  const _StageBuilder({
    required this.baseline,
    required this.prices,
    required this.today,
    required this.tracked,
    required this.logs,
  });

  final int baseline;
  final PriceHistory? prices;
  final LogicalDay today;
  final Map<LogicalDay, DailyProgress> tracked;
  final Map<LogicalDay, List<HabitLog>> logs;

  StageReport report(PlanStage stage, LogicalDay lastDay) {
    final days = lastDay.daysSince(stage.startDay) + 1;
    final daily = [
      for (var i = 0; i < days; i++) ?tracked[stage.startDay.addDays(i)],
    ];
    final used = daily.fold(0, (sum, d) => sum + d.count);

    final current = prices?.currentUnitPriceCents;
    return StageReport(
      stage: stage,
      lastDay: lastDay,
      days: days,
      used: used,
      allowed: stage.limit * days,
      daysOver: daily.where((d) => d.status == LimitStatus.over).length,
      average: used / days,
      savedCents: current == null
          ? null
          : daily
                .where((d) => d.day.isBefore(today))
                .fold<double>(
                  0,
                  (sum, d) =>
                      sum +
                      (baseline - d.count) *
                          (prices!.unitPriceCentsOn(d.day) ?? 0),
                ),
      toSaveCents: current == null
          ? null
          : math.max(0, (baseline - stage.limit) * days * current),
      toAvoid: math.max(0, (baseline - stage.limit) * days),
      mostly: ProgressCalculator.triggerBreakdown(
        daily.expand((d) => logs[d.day] ?? const <HabitLog>[]),
      ).shares.firstOrNull?.trigger,
      note: null,
      daily: daily,
    );
  }
}

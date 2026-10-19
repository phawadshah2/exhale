import 'dart:math' as math;

import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/plan/domain/entities/plan_stage.dart';
import 'package:meta/meta.dart';

/// A taper from [startLimit] per day on [startDay] to zero on [quitDay].
///
/// The limit falls evenly: on day `d` of `D` it is
/// `ceil(startLimit × (D − d) / D)`, so drops are spread across the plan
/// (9/day over 63 days drops by one every 7 days).
@immutable
class ReductionPlan {
  ReductionPlan({
    required this.startDay,
    required this.startLimit,
    required this.quitDay,
  }) {
    if (startLimit < 1) {
      throw ArgumentError.value(startLimit, 'startLimit', 'must be >= 1');
    }
    if (!quitDay.isAfter(startDay)) {
      throw ArgumentError.value(
        quitDay,
        'quitDay',
        'must be after startDay ($startDay)',
      );
    }
  }

  /// About one fewer per week.
  static LogicalDay suggestedQuitDay(LogicalDay startDay, int startLimit) =>
      startDay.addDays(math.max(7, startLimit * 7));

  final LogicalDay startDay;
  final int startLimit;
  final LogicalDay quitDay;

  int get totalDays => quitDay.daysSince(startDay);

  /// Average days between drops of one cigarette.
  double get daysPerDrop => totalDays / startLimit;

  /// Every day before [quitDay] whose limit differs from the day before.
  late final List<PlanStage> stages = List.unmodifiable(_buildStages());

  int get stageCount => stages.length;

  /// Cigarettes not smoked by [quitDay] if every limit is kept, compared
  /// with staying at [startLimit].
  late final int plannedReduction = [
    for (var d = 0; d < totalDays; d++) startLimit - _limitAt(d),
  ].fold(0, (sum, value) => sum + value);

  int limitOn(LogicalDay day) {
    if (day.isBefore(startDay)) return startLimit;
    return _limitAt(day.daysSince(startDay));
  }

  bool hasStartedOn(LogicalDay day) => !day.isBefore(startDay);

  bool isCompleteOn(LogicalDay day) => !day.isBefore(quitDay);

  /// The stage in force, or null before [startDay] and from [quitDay].
  PlanStage? stageOn(LogicalDay day) {
    if (!hasStartedOn(day) || isCompleteOn(day)) return null;
    return stages.lastWhere((stage) => !stage.startDay.isAfter(day));
  }

  /// Next day the limit goes down, or null from [quitDay].
  LogicalDay? nextDropOn(LogicalDay day) {
    if (isCompleteOn(day)) return null;
    if (!hasStartedOn(day)) {
      return stages.length > 1 ? stages[1].startDay : quitDay;
    }
    return stageOn(day)!.endDay.addDays(1);
  }

  int? daysUntilNextDrop(LogicalDay day) => nextDropOn(day)?.daysSince(day);

  /// Share of the plan's days already behind [day], from 0 to 1.
  double progressOn(LogicalDay day) =>
      (day.daysSince(startDay) / totalDays).clamp(0, 1).toDouble();

  int _limitAt(int dayIndex) {
    if (dayIndex <= 0) return startLimit;
    if (dayIndex >= totalDays) return 0;
    final remaining = totalDays - dayIndex;
    // Integer ceil(startLimit * remaining / totalDays).
    return (startLimit * remaining + totalDays - 1) ~/ totalDays;
  }

  List<PlanStage> _buildStages() {
    final stages = <PlanStage>[];
    var stageStart = 0;
    for (var d = 1; d <= totalDays; d++) {
      if (d == totalDays || _limitAt(d) != _limitAt(stageStart)) {
        stages.add(
          PlanStage(
            number: stages.length + 1,
            limit: _limitAt(stageStart),
            startDay: startDay.addDays(stageStart),
            lengthDays: d - stageStart,
          ),
        );
        stageStart = d;
      }
    }
    return stages;
  }

  @override
  bool operator ==(Object other) =>
      other is ReductionPlan &&
      other.startDay == startDay &&
      other.startLimit == startLimit &&
      other.quitDay == quitDay;

  @override
  int get hashCode => Object.hash(startDay, startLimit, quitDay);

  @override
  String toString() =>
      'ReductionPlan($startLimit/day from $startDay, quit $quitDay)';
}

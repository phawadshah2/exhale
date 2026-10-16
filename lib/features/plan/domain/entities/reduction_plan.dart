import 'dart:math' as math;

import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/plan/domain/entities/plan_stage.dart';
import 'package:meta/meta.dart';

/// A tapering schedule: [startLimit] per day from [startDay], dropping by
/// one every [stepDays] days until it reaches [targetLimit].
@immutable
class ReductionPlan {
  ReductionPlan({
    required this.startDay,
    required this.startLimit,
    this.stepDays = defaultStepDays,
    this.targetLimit = 0,
  }) {
    if (targetLimit < 0) {
      throw ArgumentError.value(targetLimit, 'targetLimit', 'must be >= 0');
    }
    if (startLimit <= targetLimit) {
      throw ArgumentError.value(
        startLimit,
        'startLimit',
        'must be greater than targetLimit ($targetLimit)',
      );
    }
    if (stepDays < 1) {
      throw ArgumentError.value(stepDays, 'stepDays', 'must be >= 1');
    }
  }

  static const int defaultStepDays = 7;

  final LogicalDay startDay;
  final int startLimit;
  final int stepDays;
  final int targetLimit;

  /// Number of stages before the target is reached.
  int get stageCount => startLimit - targetLimit;

  int get totalDays => stageCount * stepDays;

  /// First day on which the limit equals [targetLimit].
  LogicalDay get targetDay => startDay.addDays(totalDays);

  List<PlanStage> get stages =>
      List.unmodifiable(List.generate(stageCount, _stageAt));

  int limitOn(LogicalDay day) =>
      math.max(targetLimit, startLimit - _dropsBy(day));

  bool hasStartedOn(LogicalDay day) => !day.isBefore(startDay);

  bool isCompleteOn(LogicalDay day) => !day.isBefore(targetDay);

  /// The active stage, or null before [startDay] and once complete.
  PlanStage? stageOn(LogicalDay day) {
    if (!hasStartedOn(day) || isCompleteOn(day)) return null;
    return _stageAt(_dropsBy(day));
  }

  /// Next day the limit goes down, or null once complete.
  LogicalDay? nextDropOn(LogicalDay day) {
    if (isCompleteOn(day)) return null;
    return startDay.addDays((_dropsBy(day) + 1) * stepDays);
  }

  int? daysUntilNextDrop(LogicalDay day) => nextDropOn(day)?.daysSince(day);

  /// Share of the plan's days already behind [day], from 0 to 1.
  double progressOn(LogicalDay day) =>
      (day.daysSince(startDay) / totalDays).clamp(0, 1).toDouble();

  int _dropsBy(LogicalDay day) {
    if (!hasStartedOn(day)) return 0;
    return day.daysSince(startDay) ~/ stepDays;
  }

  PlanStage _stageAt(int index) => PlanStage(
    number: index + 1,
    limit: startLimit - index,
    startDay: startDay.addDays(index * stepDays),
    lengthDays: stepDays,
  );

  @override
  bool operator ==(Object other) =>
      other is ReductionPlan &&
      other.startDay == startDay &&
      other.startLimit == startLimit &&
      other.stepDays == stepDays &&
      other.targetLimit == targetLimit;

  @override
  int get hashCode => Object.hash(startDay, startLimit, stepDays, targetLimit);

  @override
  String toString() =>
      'ReductionPlan($startLimit → $targetLimit, -1 every $stepDays days '
      'from $startDay)';
}

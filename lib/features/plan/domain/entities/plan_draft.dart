import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:meta/meta.dart';

/// Unvalidated plan input from the setup or edit forms.
@immutable
class PlanDraft {
  const PlanDraft({
    required this.startDay,
    required this.startLimit,
    this.stepDays = ReductionPlan.defaultStepDays,
    this.targetLimit = 0,
  });

  final LogicalDay startDay;
  final int startLimit;
  final int stepDays;
  final int targetLimit;

  PlanDraft copyWith({
    LogicalDay? startDay,
    int? startLimit,
    int? stepDays,
    int? targetLimit,
  }) => PlanDraft(
    startDay: startDay ?? this.startDay,
    startLimit: startLimit ?? this.startLimit,
    stepDays: stepDays ?? this.stepDays,
    targetLimit: targetLimit ?? this.targetLimit,
  );

  @override
  bool operator ==(Object other) =>
      other is PlanDraft &&
      other.startDay == startDay &&
      other.startLimit == startLimit &&
      other.stepDays == stepDays &&
      other.targetLimit == targetLimit;

  @override
  int get hashCode => Object.hash(startDay, startLimit, stepDays, targetLimit);
}

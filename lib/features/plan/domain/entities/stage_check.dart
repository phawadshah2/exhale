import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:meta/meta.dart';

enum StageOutcome { passed, skipped, hold, review, reassess }

/// The check of one ended stage's window. A hold, review or reassess card
/// shows until [answeredAt] is set.
@immutable
class StageCheck {
  const StageCheck({
    required this.planStartDay,
    required this.windowEndDay,
    required this.checkDay,
    required this.outcome,
    this.answeredAt,
  });

  /// Names the plan the check belongs to.
  final LogicalDay planStartDay;

  /// The last day of the window checked.
  final LogicalDay windowEndDay;

  /// The logical day the check ran.
  final LogicalDay checkDay;

  final StageOutcome outcome;
  final DateTime? answeredAt;

  @override
  bool operator ==(Object other) =>
      other is StageCheck &&
      other.planStartDay == planStartDay &&
      other.windowEndDay == windowEndDay &&
      other.checkDay == checkDay &&
      other.outcome == outcome &&
      other.answeredAt == answeredAt;

  @override
  int get hashCode =>
      Object.hash(planStartDay, windowEndDay, checkDay, outcome, answeredAt);

  @override
  String toString() =>
      'StageCheck(${outcome.name} for the window ending $windowEndDay, '
      'run $checkDay)';
}

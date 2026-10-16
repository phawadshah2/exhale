import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:meta/meta.dart';

/// One step of a plan: a fixed daily limit held for [lengthDays] days.
@immutable
class PlanStage {
  const PlanStage({
    required this.number,
    required this.limit,
    required this.startDay,
    required this.lengthDays,
  });

  /// 1-based ("Week 3 of 9").
  final int number;
  final int limit;
  final LogicalDay startDay;
  final int lengthDays;

  /// Last day of the stage (inclusive).
  LogicalDay get endDay => startDay.addDays(lengthDays - 1);

  bool contains(LogicalDay day) =>
      !day.isBefore(startDay) && !day.isAfter(endDay);

  /// 1-based position of [day] inside the stage ("Day 4 of 7").
  int dayNumberOf(LogicalDay day) => day.daysSince(startDay) + 1;

  @override
  bool operator ==(Object other) =>
      other is PlanStage &&
      other.number == number &&
      other.limit == limit &&
      other.startDay == startDay &&
      other.lengthDays == lengthDays;

  @override
  int get hashCode => Object.hash(number, limit, startDay, lengthDays);

  @override
  String toString() => 'PlanStage(#$number, $limit/day, $startDay..$endDay)';
}

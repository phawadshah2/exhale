import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:meta/meta.dart';

/// A pause inside a plan: from [startDay] the limit stays where it was for
/// [days] days, and every later drop and the quit date move by as many.
@immutable
class PlanHold {
  const PlanHold({required this.startDay, this.days = 7});

  final LogicalDay startDay;
  final int days;

  @override
  bool operator ==(Object other) =>
      other is PlanHold && other.startDay == startDay && other.days == days;

  @override
  int get hashCode => Object.hash(startDay, days);

  @override
  String toString() => 'PlanHold($days days from $startDay)';
}

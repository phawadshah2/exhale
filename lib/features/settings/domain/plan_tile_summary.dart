import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:meta/meta.dart';

/// What a Settings tile shows: a small eyebrow, a big value and an optional
/// line under it.
@immutable
class TileSummary {
  const TileSummary({required this.eyebrow, required this.value, this.line});

  final String eyebrow;
  final String value;
  final String? line;

  @override
  bool operator ==(Object other) =>
      other is TileSummary &&
      other.eyebrow == eyebrow &&
      other.value == value &&
      other.line == line;

  @override
  int get hashCode => Object.hash(eyebrow, value, line);

  @override
  String toString() => 'TileSummary($eyebrow, $value, $line)';
}

/// The plan tile: the quit date and the days to go.
TileSummary planTileSummary({
  required TrackedHabit habit,
  required PlanHistory history,
  required LogicalDay today,
}) {
  final plan = history.current;
  final quit = AppFormat.monthDay(plan.quitDay);
  final eyebrow = '${habit.habit.name} plan';
  if (!plan.hasStartedOn(today)) {
    return TileSummary(
      eyebrow: eyebrow,
      value: quit,
      line: 'Starts ${AppFormat.monthDay(plan.startDay)}',
    );
  }
  if (plan.isCompleteOn(today)) {
    return TileSummary(eyebrow: eyebrow, value: 'Quit day', line: quit);
  }
  final left = plan.quitDay.daysSince(today);
  return TileSummary(
    eyebrow: eyebrow,
    value: quit,
    line: left == 1 ? '1 day to go' : '$left days to go',
  );
}

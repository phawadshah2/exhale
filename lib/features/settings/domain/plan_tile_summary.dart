import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:meta/meta.dart';

/// What a Settings tile shows: a small eyebrow, a big value and an optional
/// line under it.
@immutable
class TileSummary {
  const TileSummary({
    required this.eyebrow,
    required this.value,
    this.line,
    this._spoken,
  });

  final String eyebrow;
  final String value;
  final String? line;
  final String? _spoken;

  /// What VoiceOver reads: the three lines, unless a fuller wording is set.
  String get semanticsLabel => _spoken ?? [eyebrow, value, ?line].join(', ');

  @override
  bool operator ==(Object other) =>
      other is TileSummary &&
      other.eyebrow == eyebrow &&
      other.value == value &&
      other.line == line &&
      other._spoken == _spoken;

  @override
  int get hashCode => Object.hash(eyebrow, value, line, _spoken);

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
  String spoken(String line) =>
      '$eyebrow, quit ${AppFormat.month(plan.quitDay)} '
      '${plan.quitDay.day}, $line';
  if (!plan.hasStartedOn(today)) {
    final line = 'Starts ${AppFormat.monthDay(plan.startDay)}';
    return TileSummary(
      eyebrow: eyebrow,
      value: quit,
      line: line,
      spoken: spoken(line),
    );
  }
  if (plan.isCompleteOn(today)) {
    return TileSummary(eyebrow: eyebrow, value: 'Quit day', line: quit);
  }
  final left = plan.quitDay.daysSince(today);
  final line = left == 1 ? '1 day to go' : '$left days to go';
  return TileSummary(
    eyebrow: eyebrow,
    value: quit,
    line: line,
    spoken: spoken(line),
  );
}

import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:meta/meta.dart';

enum ChoiceKind { realNumber, slowDown, keep, startAgain }

/// One way to go on after a review or reassess check, worked out before
/// anything is saved.
@immutable
class PlanChoice {
  const PlanChoice({
    required this.kind,
    required this.limit,
    required this.quitDay,
    required this.daysPerDrop,
    required this.changeDays,
  });

  final ChoiceKind kind;

  /// The daily limit from today.
  final int limit;
  final LogicalDay quitDay;

  /// Days between drops of one unit.
  final double daysPerDrop;

  /// Days the quit date moves against the current plan's.
  final int changeDays;

  /// The limit falls about every day, which the sheet words differently.
  bool get dropsAboutDaily => daysPerDrop < PlanChoices.dailyPace;

  @override
  bool operator ==(Object other) =>
      other is PlanChoice &&
      other.kind == kind &&
      other.limit == limit &&
      other.quitDay == quitDay &&
      other.daysPerDrop == daysPerDrop &&
      other.changeDays == changeDays;

  @override
  int get hashCode =>
      Object.hash(kind, limit, quitDay, daysPerDrop, changeDays);

  @override
  String toString() =>
      'PlanChoice(${kind.name}: $limit a day until $quitDay, '
      'a drop every $daysPerDrop days)';
}

/// The choices of Stages spec section 4, as pure functions.
abstract final class PlanChoices {
  static const int maxLimit = 80;

  /// A pace under this many days a drop reads as "about every day".
  static const double dailyPace = 1.5;

  /// Start from the real number, slow down, or keep. [windowAverage] is the
  /// review sheet's average of the two failed weeks, rounded up,
  /// [checkedLimit] the limit of the stage that failed.
  static List<PlanChoice> review({
    required ReductionPlan current,
    required LogicalDay today,
    required int windowAverage,
    required int checkedLimit,
  }) {
    final real = _limit(windowAverage);
    final slow = _limit(checkedLimit);
    return [
      PlanChoice(
        kind: ChoiceKind.realNumber,
        limit: real,
        quitDay: today.addDays(_lengthDays(current, real, 1)),
        daysPerDrop: current.daysPerDrop,
        changeDays: _change(current, today, _lengthDays(current, real, 1)),
      ),
      PlanChoice(
        kind: ChoiceKind.slowDown,
        limit: slow,
        quitDay: today.addDays(_lengthDays(current, slow, 2)),
        daysPerDrop: current.daysPerDrop * 2,
        changeDays: _change(current, today, _lengthDays(current, slow, 2)),
      ),
      _keep(current, today),
    ];
  }

  /// Start again from [average] (the 14-day average rounded up), or keep.
  static List<PlanChoice> reassess({
    required ReductionPlan current,
    required LogicalDay today,
    required int average,
  }) {
    final limit = _limit(average);
    final suggested = ReductionPlan.suggestedQuitDay(today, limit);
    final quitDay = suggested.isAfter(current.quitDay)
        ? suggested
        : current.quitDay;
    return [
      PlanChoice(
        kind: ChoiceKind.startAgain,
        limit: limit,
        quitDay: quitDay,
        daysPerDrop: quitDay.daysSince(today) / limit,
        changeDays: quitDay.daysSince(current.quitDay),
      ),
      _keep(current, today),
    ];
  }

  static PlanChoice _keep(ReductionPlan current, LogicalDay today) =>
      PlanChoice(
        kind: ChoiceKind.keep,
        limit: current.limitOn(today),
        quitDay: current.quitDay,
        daysPerDrop: current.daysPerDrop,
        changeDays: 0,
      );

  static int _limit(int value) => value.clamp(1, maxLimit);

  /// `limit × pace × [slowBy]` days, rounded up. Integer maths, so a whole
  /// number of days never gains one from floating point.
  static int _lengthDays(ReductionPlan current, int limit, int slowBy) {
    final agreedDays = current.agreedQuitDay.daysSince(current.startDay);
    final perUnit = current.startLimit;
    return (limit * agreedDays * slowBy + perUnit - 1) ~/ perUnit;
  }

  static int _change(ReductionPlan current, LogicalDay today, int length) =>
      today.addDays(length).daysSince(current.quitDay);
}

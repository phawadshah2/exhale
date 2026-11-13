import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';

/// One of the plan screen's three ways to zero.
class OnboardingPace {
  const OnboardingPace(this.name, this.weeks);

  final String name;
  final int weeks;

  int get days => weeks * 7;

  static const List<OnboardingPace> all = [
    OnboardingPace('Brisk', 4),
    OnboardingPace('Steady', 8),
    OnboardingPace('Gentle', 12),
  ];

  /// The index of the pace nearest the suggested quit date for
  /// [startLimit]; a tie goes to the longer pace.
  static int suggestedIndex(LogicalDay startDay, int startLimit) {
    final target = ReductionPlan.suggestedQuitDay(
      startDay,
      startLimit,
    ).daysSince(startDay);
    var best = 0;
    for (var i = 1; i < all.length; i++) {
      if ((all[i].days - target).abs() <= (all[best].days - target).abs()) {
        best = i;
      }
    }
    return best;
  }

  /// The quit day of the pace nearest the suggested date.
  static LogicalDay suggestedQuitDay(LogicalDay startDay, int startLimit) =>
      startDay.addDays(all[suggestedIndex(startDay, startLimit)].days);
}

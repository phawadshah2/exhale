import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';

extension HabitWording on Habit {
  /// "Vape-free", or "At zero" when the habit has no natural word.
  String get freeTitle {
    final label = freeLabel;
    if (label == null) return 'At zero';
    return '${label[0].toUpperCase()}${label.substring(1)}';
  }

  /// "Vape-free day" / "Zero day".
  String get freeDayTitle => freeLabel == null ? 'Zero day' : '$freeTitle day';

  /// "Cigarettes avoided".
  String get avoidedTitle =>
      '${units[0].toUpperCase()}${units.substring(1)} avoided';

  /// "Stage 2 of 9 · Daily limit: 11", or the plan's start or quit date
  /// outside its stages.
  String stageLine(ReductionPlan plan, LogicalDay today) {
    final stage = plan.stageOn(today);
    if (!plan.hasStartedOn(today)) {
      return 'Plan starts ${AppFormat.monthDay(plan.startDay)} · '
          'Daily limit: ${plan.startLimit}';
    }
    if (stage == null) {
      return '$freeTitle since ${AppFormat.monthDay(plan.quitDay)}';
    }
    return 'Stage ${stage.number} of ${plan.stageCount} · '
        'Daily limit: ${stage.limit}';
  }

  /// "Drops to 8 in 3d", "Quit day tomorrow", or [freeTitle] from the quit
  /// date.
  String nextTarget(ReductionPlan plan, LogicalDay today) {
    final days = plan.daysUntilNextDrop(today);
    if (days == null) return freeTitle;
    final next = plan.limitOn(plan.nextDropOn(today)!);
    return next == 0
        ? (days == 1 ? 'Quit day tomorrow' : 'Quit day in ${days}d')
        : (days == 1
              ? 'Drops to $next tomorrow'
              : 'Drops to $next in ${days}d');
  }
}

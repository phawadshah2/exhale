import 'package:exhale/core/domain/time/logical_day.dart';
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

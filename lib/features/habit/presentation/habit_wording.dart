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

  /// The closing line of the reassess sheet.
  String get supportLine => switch (kind) {
    HabitKind.vaping || HabitKind.smoking || HabitKind.nicotinePouches =>
      'If this keeps being hard, a doctor, pharmacist or local quit service '
          'can help.',
    _ =>
      'If this keeps being hard, a doctor or local support service can help.',
  };

  /// A safety line for alcohol; null for every other habit.
  String? get stopSuddenlyLine => kind == HabitKind.alcohol
      ? "If you drink heavily, don't stop suddenly without medical advice. "
            'It can be dangerous.'
      : null;
}

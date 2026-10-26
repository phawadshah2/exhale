import 'package:exhale/features/habit/domain/entities/habit.dart';

extension HabitWording on Habit {
  /// "Vape-free", or "At zero" when the habit has no natural word.
  String get freeTitle {
    final label = freeLabel;
    if (label == null) return 'At zero';
    return '${label[0].toUpperCase()}${label.substring(1)}';
  }

  /// "Vape-free day" / "Zero day".
  String get freeDayTitle => freeLabel == null ? 'Zero day' : '$freeTitle day';
}

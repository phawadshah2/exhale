import 'package:meta/meta.dart';

@immutable
class HomeStats {
  const HomeStats({
    required this.dayNumber,
    required this.streakDays,
    required this.baseline,
    required this.recentAverage,
    required this.avoided,
    required this.moneySavedCents,
  });

  /// 1 on the first plan day.
  final int dayNumber;

  /// Consecutive days within limit, ending today.
  final int streakDays;

  /// Daily amount the user started from.
  final int baseline;

  /// Average of the last 7 completed days, or null before any completes.
  final double? recentAverage;

  /// Cigarettes not smoked versus the baseline, completed days only.
  final int avoided;

  /// Null when no pack price is set.
  final double? moneySavedCents;

  /// Change of [recentAverage] versus [baseline]: -0.33 means 33% less.
  double? get changeFromBaseline =>
      recentAverage == null ? null : (recentAverage! - baseline) / baseline;

  @override
  bool operator ==(Object other) =>
      other is HomeStats &&
      other.dayNumber == dayNumber &&
      other.streakDays == streakDays &&
      other.baseline == baseline &&
      other.recentAverage == recentAverage &&
      other.avoided == avoided &&
      other.moneySavedCents == moneySavedCents;

  @override
  int get hashCode => Object.hash(
    dayNumber,
    streakDays,
    baseline,
    recentAverage,
    avoided,
    moneySavedCents,
  );
}

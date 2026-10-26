import 'package:meta/meta.dart';

/// How a week or month went against the plan, counting plan days only.
@immutable
class PeriodStats {
  const PeriodStats({
    required this.logged,
    required this.allowed,
    required this.allowedByToday,
    required this.avgPerDay,
    required this.daysOver,
    required this.daysOnTrack,
  });

  /// Logs on plan days up to today.
  final int logged;

  /// Sum of each plan day's own limit across the whole period.
  final int allowed;

  /// The same sum, through today only.
  final int allowedByToday;

  /// Logs per tracked day, or null when no plan day has been tracked yet.
  final double? avgPerDay;

  final int daysOver;

  /// Tracked days that stayed at or under their limit.
  final int daysOnTrack;

  /// Allowance left (positive) or used past (negative) so far.
  int get underBy => allowedByToday - logged;

  @override
  bool operator ==(Object other) =>
      other is PeriodStats &&
      other.logged == logged &&
      other.allowed == allowed &&
      other.allowedByToday == allowedByToday &&
      other.avgPerDay == avgPerDay &&
      other.daysOver == daysOver &&
      other.daysOnTrack == daysOnTrack;

  @override
  int get hashCode => Object.hash(
    logged,
    allowed,
    allowedByToday,
    avgPerDay,
    daysOver,
    daysOnTrack,
  );

  @override
  String toString() =>
      'PeriodStats($logged logged, $allowed allowed, '
      '$daysOver over, $daysOnTrack on track)';
}

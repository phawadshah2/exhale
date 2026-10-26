import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:meta/meta.dart';

/// Every plan day from the first plan, for the "All" chart.
@immutable
class AllTimeSeries {
  AllTimeSeries({
    required this.start,
    required this.end,
    required this.today,
    required List<int> counts,
    required List<double>? average7,
    required List<int> limits,
    required this.weekly,
  }) : counts = List.unmodifiable(counts),
       average7 = average7 == null ? null : List.unmodifiable(average7),
       limits = List.unmodifiable(limits);

  final LogicalDay start;

  /// The later of the quit day and today.
  final LogicalDay end;

  final LogicalDay today;

  /// Logs per plot point from [start] through [today].
  final List<int> counts;

  /// Trailing 7-day mean for each point of [counts]. Null under 14 days of
  /// history, and when [weekly] since weekly sums are already smoothed.
  final List<double>? average7;

  /// Limit per plot point from [start] through [end].
  final List<int> limits;

  /// True past 180 days: each point is a 7-day block counted from [start].
  final bool weekly;
}

import 'dart:math' as math;

import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/tracking/domain/entities/limit_status.dart';
import 'package:meta/meta.dart';

/// How one day went against that day's limit.
@immutable
class DailyProgress {
  const DailyProgress({
    required this.day,
    required this.count,
    required this.limit,
  }) : assert(count >= 0, 'count must be >= 0'),
       assert(limit >= 0, 'limit must be >= 0');

  final LogicalDay day;
  final int count;
  final int limit;

  int get remaining => math.max(0, limit - count);

  int get overBy => math.max(0, count - limit);

  LimitStatus get status => LimitStatus.of(count: count, limit: limit);

  /// Ring fill from 0 to 1; full once the limit is reached or passed.
  double get usedFraction {
    if (limit == 0) return count == 0 ? 0 : 1;
    return math.min(1, count / limit);
  }

  @override
  bool operator ==(Object other) =>
      other is DailyProgress &&
      other.day == day &&
      other.count == count &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(day, count, limit);

  @override
  String toString() => 'DailyProgress($day, $count/$limit)';
}

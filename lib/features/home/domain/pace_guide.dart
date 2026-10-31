import 'package:exhale/core/domain/time/day_boundary.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/settings/domain/entities/day_window.dart';
import 'package:meta/meta.dart';

/// When the next use would keep the user on track for today's limit.
@immutable
class PaceGuide {
  const PaceGuide({required this.next, required this.pace});

  final DateTime next;
  final Duration pace;

  /// Null when there is nothing to pace: at or over the limit, on a limit of
  /// 0, or outside the waking window.
  static PaceGuide? compute({
    required DateTime now,
    required LogicalDay day,
    required DayBoundary boundary,
    required DayWindow window,
    required int limit,
    required int countToday,
    DateTime? lastLogToday,
  }) {
    if (limit <= 0 || countToday >= limit) return null;

    final wake = _latest(_onDay(day, window.wakeMinute), boundary.startOf(day));
    final bed = _earliest(
      _onDay(day, window.wakeMinute + window.awakeMinutes),
      boundary.endOf(day),
    );
    if (now.isBefore(wake) || !now.isBefore(bed)) return null;

    final pace = Duration(
      microseconds:
          bed.difference(_latest(now, wake)).inMicroseconds ~/
          (limit - countToday),
    );
    return PaceGuide(
      next: _latest(lastLogToday ?? wake, wake).add(pace),
      pace: pace,
    );
  }

  /// [minute] may run past midnight into the next calendar date.
  static DateTime _onDay(LogicalDay day, int minute) =>
      DateTime(day.year, day.month, day.day, 0, minute);

  static DateTime _latest(DateTime a, DateTime b) => a.isAfter(b) ? a : b;

  static DateTime _earliest(DateTime a, DateTime b) => a.isBefore(b) ? a : b;
}

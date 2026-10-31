import 'package:exhale/core/domain/time/day_boundary.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/settings/domain/entities/day_window.dart';
import 'package:meta/meta.dart';

/// When the next use would keep the user on track for today's limit.
@immutable
class PaceGuide {
  const PaceGuide({
    required this.next,
    required this.gap,
    required this.pace,
    required this.bed,
  });

  final DateTime next;

  /// From the last log (or wake) to [next]; holds still until the next log.
  final Duration gap;

  final Duration pace;

  /// The end of the waking window, cut at the day's end.
  final DateTime bed;

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
    List<DateTime> earlierLogsToday = const [],
  }) {
    if (limit <= 0 || countToday >= limit) return null;

    final wake = _latest(_onDay(day, window.wakeMinute), boundary.startOf(day));
    final bed = _earliest(
      _onDay(day, window.wakeMinute + window.awakeMinutes),
      boundary.endOf(day),
    );
    if (now.isBefore(wake) || !now.isBefore(bed)) return null;

    // A guide to cutting down never suggests going faster than the even rate.
    final even = bed.difference(wake) ~/ limit;
    Duration gap(DateTime from, int count) {
      final share = bed.difference(from) ~/ (limit - count);
      return share > even ? share : even;
    }

    // Replayed from the day's logs, so it holds still until the next one and
    // an undone or added log corrects it. Time left on the timer when a log
    // comes carries into the next gap.
    final logs = [...earlierLogsToday, ?lastLogToday];
    var count = countToday - logs.length;
    var anchor = wake;
    var due = wake.add(gap(wake, count));
    for (final log in logs) {
      count++;
      final left = log.isBefore(wake) ? Duration.zero : due.difference(log);
      anchor = _latest(log, wake);
      due = anchor.add(gap(anchor, count));
      if (left > Duration.zero) due = due.add(left);
    }

    final next = _earliest(due, bed);
    return PaceGuide(
      next: next,
      gap: next.difference(anchor),
      pace: gap(_latest(now, wake), countToday),
      bed: bed,
    );
  }

  /// [minute] may run past midnight into the next calendar date.
  static DateTime _onDay(LogicalDay day, int minute) =>
      DateTime(day.year, day.month, day.day, 0, minute);

  static DateTime _latest(DateTime a, DateTime b) => a.isAfter(b) ? a : b;

  static DateTime _earliest(DateTime a, DateTime b) => a.isBefore(b) ? a : b;
}

/// A [PaceGuide] at one moment: what the countdown to the next log shows.
@immutable
class NextLogTimer {
  const NextLogTimer({required this.guide, required this.now});

  final PaceGuide guide;
  final DateTime now;

  /// Negative once [PaceGuide.next] has passed.
  Duration get left => guide.next.difference(now);

  bool get isPast => left <= Duration.zero;

  /// What is left of the gap, from 1 just after a log to 0 at the next one.
  double get fraction =>
      (left.inMicroseconds / guide.gap.inMicroseconds).clamp(0.0, 1.0);

  /// False when one more gap would run past bed.
  bool get showsPace => !now.add(guide.pace).isAfter(guide.bed);

  @override
  bool operator ==(Object other) =>
      other is NextLogTimer &&
      other.now == now &&
      other.guide.next == guide.next &&
      other.guide.gap == guide.gap &&
      other.guide.pace == guide.pace &&
      other.guide.bed == guide.bed;

  @override
  int get hashCode =>
      Object.hash(now, guide.next, guide.gap, guide.pace, guide.bed);
}

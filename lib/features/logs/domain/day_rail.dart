import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/home/domain/pace_guide.dart';
import 'package:exhale/features/settings/domain/entities/day_window.dart';
import 'package:exhale/features/tracking/domain/entities/habit_log.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:meta/meta.dart';

@immutable
sealed class RailEntry {
  const RailEntry();
}

final class RailWake extends RailEntry {
  const RailWake(this.at);

  final DateTime at;
}

final class RailBed extends RailEntry {
  const RailBed(this.at);

  final DateTime at;
}

final class RailLog extends RailEntry {
  const RailLog(this.log, {required this.over});

  final HabitLog log;
  final bool over;
}

final class RailLimitReached extends RailEntry {
  const RailLimitReached(this.limit);

  final int limit;
}

final class RailGap extends RailEntry {
  const RailGap(this.gap, {required this.longest});

  final Duration gap;
  final bool longest;
}

final class RailNext extends RailEntry {
  const RailNext(this.at);

  final DateTime at;
}

final class RailNothingYet extends RailEntry {
  const RailNothingYet();
}

final class RailThenNothing extends RailEntry {
  const RailThenNothing();
}

final class RailNothingLogged extends RailEntry {
  const RailNothingLogged();
}

abstract final class DayRail {
  /// [logs] are oldest first. A null [limit] means before the plan: logs and
  /// gaps only. A gap follows the earlier log, so a mark between two logs
  /// comes after it.
  static List<RailEntry> build({
    required List<HabitLog> logs,
    required int? limit,
    required DayWindow? window,
    required LogicalDay day,
    required bool isToday,
    required DateTime? next,
    Trigger? filter,
  }) {
    if (filter != null) {
      return [
        for (final (i, log) in logs.indexed)
          if (log.trigger == filter)
            RailLog(log, over: limit != null && i >= limit),
      ];
    }

    final marked = limit != null ? window : null;
    var wake = marked == null ? null : PaceGuide.onDay(day, marked.wakeMinute);
    var bed = marked == null
        ? null
        : PaceGuide.onDay(day, marked.wakeMinute + marked.awakeMinutes);
    final gaps = [
      for (var i = 1; i < logs.length; i++)
        logs[i].loggedAt.difference(logs[i - 1].loggedAt),
    ];
    final longest = _longest(gaps);

    final rail = <RailEntry>[];
    for (final (i, log) in logs.indexed) {
      if (i > 0) rail.add(RailGap(gaps[i - 1], longest: i - 1 == longest));
      if (wake != null && !wake.isAfter(log.loggedAt)) {
        rail.add(RailWake(wake));
        wake = null;
      }
      if (bed != null && bed.isBefore(log.loggedAt)) {
        rail.add(RailBed(bed));
        bed = null;
      }
      if (i == limit) rail.add(RailLimitReached(i));
      rail.add(RailLog(log, over: limit != null && i >= limit));
    }

    if (wake != null) rail.add(RailWake(wake));
    if (limit == null) {
      if (logs.isEmpty) rail.add(const RailNothingLogged());
    } else if (isToday) {
      if (next != null) rail.add(RailNext(next));
      rail.add(const RailNothingYet());
    } else {
      rail.add(
        logs.isEmpty ? const RailNothingLogged() : const RailThenNothing(),
      );
    }
    if (bed != null) rail.add(RailBed(bed));
    return rail;
  }

  /// The index of the longest gap, the earliest on a tie; null under two gaps.
  static int? _longest(List<Duration> gaps) {
    if (gaps.length < 2) return null;
    var longest = 0;
    for (var i = 1; i < gaps.length; i++) {
      if (gaps[i] > gaps[longest]) longest = i;
    }
    return longest;
  }
}

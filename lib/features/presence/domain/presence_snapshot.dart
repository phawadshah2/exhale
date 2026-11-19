import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:exhale/features/habit/presentation/habit_wording.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/presence/domain/encouragement.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:meta/meta.dart';

/// What the widgets, Log one and the Live Activity read from the App Group.
@immutable
class PresenceSnapshot {
  const PresenceSnapshot._(this._json);

  /// Limits and stages come from [history] (holds already on its plans);
  /// counts are written for past days and [today] only.
  factory PresenceSnapshot.build({
    required DateTime now,
    required LogicalDay today,
    required AppSettings settings,
    required TrackedHabit habit,
    required PlanHistory history,
    required Map<LogicalDay, int> counts,
    required List<DateTime> todayLogs,
    required bool entitled,
    required LinePair lastPair,
  }) {
    final window = settings.dayWindow;
    return PresenceSnapshot._({
      'version': version,
      'writtenAt': _instant(now),
      'entitled': entitled,
      'resetHour': settings.dayResetHour,
      'wakeMinute': window?.wakeMinute,
      'awakeMinutes': window?.awakeMinutes,
      'habit': {
        'name': habit.habit.name,
        'kind': habit.habit.kind.name,
        'reason': habit.reason,
        'freeDayTitle': habit.habit.freeDayTitle,
      },
      'quitDay': history.current.quitDay.toString(),
      'days': [
        for (var offset = -daysEachSide; offset <= daysEachSide; offset++)
          _day(today.addDays(offset), history, counts, counted: offset <= 0),
      ],
      'todayLogs': [for (final log in todayLogs) _instant(log)],
      'showLiveActivity': settings.showLiveActivity,
      'lines': encouragementLines,
      'lastPair': {'counting': lastPair.counting, 'waiting': lastPair.waiting},
    });
  }

  static const int version = 1;
  static const int daysEachSide = 62;

  final Map<String, Object?> _json;

  Map<String, Object?> toJson() => _json;

  static Map<String, Object?> _day(
    LogicalDay day,
    PlanHistory history,
    Map<LogicalDay, int> counts, {
    required bool counted,
  }) {
    final plan = history.planOn(day);
    return {
      'day': day.toString(),
      'limit': plan.limitOn(day),
      'stage': plan.stageOn(day)?.number,
      'stageCount': plan.stageCount,
      if (counted) 'count': counts[day] ?? 0,
    };
  }

  static String _instant(DateTime time) => time.toUtc().toIso8601String();
}

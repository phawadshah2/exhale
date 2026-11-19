import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/providers/clock_providers.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/home/domain/pace_guide.dart';
import 'package:exhale/features/paywall/domain/entities/access.dart';
import 'package:exhale/features/paywall/presentation/providers/paywall_providers.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:exhale/features/presence/domain/activity_content.dart';
import 'package:exhale/features/presence/domain/encouragement.dart';
import 'package:exhale/features/presence/domain/presence_snapshot.dart';
import 'package:exhale/features/presence/domain/repositories/presence_repository.dart';
import 'package:exhale/features/presence/domain/usecases/drain_external_logs.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/tracking/domain/entities/habit_log.dart';
import 'package:exhale/features/tracking/domain/entities/period_range.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// What the Live Activity shows for [timer]; null ends it: no access, the
/// switch off, no countdown, or [ActivityContent.quietAfter] past due.
ActivityContent? activityFor({
  required NextLogTimer? timer,
  required bool entitled,
  required bool enabled,
  required int count,
  required int limit,
  required int daysToGo,
  required LinePair lines,
}) {
  if (!entitled || !enabled || timer == null) return null;
  final content = ActivityContent(
    next: timer.guide.next,
    gap: timer.guide.gap,
    count: count,
    limit: limit,
    daysToGo: daysToGo,
    countingLine: lines.counting,
    waitingLine: lines.waiting,
  );
  return timer.now.isBefore(content.staleAt) ? content : null;
}

final presenceRepositoryProvider = Provider<PresenceRepository>(
  (ref) => sl<PresenceRepository>(),
);

final drainExternalLogsProvider = Provider<DrainExternalLogs>(
  (ref) => sl<DrainExternalLogs>(),
);

final presenceRandomProvider = Provider<Random>((ref) => Random());

/// Everything a snapshot or the activity depends on; a change syncs again.
/// Null until the habit has loaded.
final _presenceTriggerProvider = Provider<Object?>((ref) {
  final habit = ref.watch(primaryHabitProvider);
  if (habit == null) return null;
  final today = ref.watch(todayProvider);
  return (
    habit,
    today,
    ref.watch(currentSettingsProvider),
    ref.watch(accessProvider),
    ref.watch(planHistoryProvider(habit.id)).value,
    ref
        .watch(
          logsInRangeProvider((
            habitId: habit.id,
            range: PeriodRange(
              today.addDays(-PresenceSnapshot.daysEachSide),
              today,
            ),
          )),
        )
        .value,
  );
});

/// Keeps the App Group snapshot and the Live Activity in step with the app.
/// Kept alive for the app's life by `ExhaleApp`.
final presenceSyncProvider = Provider<PresenceSync>((ref) {
  final sync = PresenceSync(ref);
  ref.onDispose(sync.dispose);
  return sync;
});

class PresenceSync {
  PresenceSync(this._ref) {
    _pair = pickLinePair(_ref.read(presenceRandomProvider));
    _queueSubscription = _ref
        .read(presenceRepositoryProvider)
        .queueChanged
        .listen((_) => unawaited(request(drain: true)));
    _ref.listen<Object?>(_presenceTriggerProvider, (previous, next) {
      if (next == null) return;
      // The first time the habit is known is the start: drain first.
      unawaited(request(drain: previous == null));
    }, fireImmediately: true);
  }

  final Ref _ref;
  late final StreamSubscription<void> _queueSubscription;
  late LinePair _pair;
  bool _disposed = false;

  /// What the activity was last told: content, or null once ended. Unknown
  /// at start, so the first sync without a countdown ends any activity that
  /// Log one started while the app was closed.
  ActivityContent? _shown;
  bool _shownKnown = false;

  bool _pending = false;
  bool _pendingDrain = false;
  Future<void>? _running;

  /// Completes once no sync is in flight.
  @visibleForTesting
  Future<void> get idle => _running ?? Future<void>.value();

  /// Drains first when the app comes back, then syncs; an activity past its
  /// stale date ends.
  Future<void> resume() => request(drain: true);

  /// Syncs once the one in flight is done; requests made meanwhile merge
  /// into a single run that reads the latest state.
  Future<void> request({bool drain = false}) {
    _pending = true;
    _pendingDrain = _pendingDrain || drain;
    return _running ??= _runPending();
  }

  Future<void> _runPending() async {
    try {
      while (_pending && !_disposed) {
        _pending = false;
        final drain = _pendingDrain;
        _pendingDrain = false;
        await _sync(drain: drain);
      }
    } finally {
      _running = null;
    }
  }

  Future<void> _sync({required bool drain}) async {
    final habit = _ref.read(primaryHabitProvider);
    if (habit == null) return;
    if (drain) {
      final drained = await _ref.read(drainExternalLogsProvider)(habit.id);
      if (drained case FailureResult(:final failure)) {
        _log('Drain failed: $failure');
      }
    }
    if (_disposed) return;

    // Read from storage, not the providers, so a log just drained is in.
    final settings = await _value(
      _ref.read(settingsRepositoryProvider).get(),
      _ref.read(currentSettingsProvider),
    );
    final history = await _value<PlanHistory?>(
      _ref.read(planRepositoryProvider).getHistory(habit.id),
      null,
    );
    if (history == null || _disposed) return;
    final now = _ref.read(clockProvider).now();
    final boundary = settings.dayBoundary;
    final today = boundary.dayOf(now);
    final logs = await _value<List<HabitLog>?>(
      _ref
          .read(habitLogRepositoryProvider)
          .getLogs(
            habitId: habit.id,
            from: boundary.startOf(
              today.addDays(-PresenceSnapshot.daysEachSide),
            ),
            to: boundary.endOf(today),
          ),
      null,
    );
    if (logs == null || _disposed) return;

    final counts = <LogicalDay, int>{};
    final todayLogs = <DateTime>[];
    for (final log in logs) {
      final day = boundary.dayOf(log.loggedAt);
      counts[day] = (counts[day] ?? 0) + 1;
      if (day == today) todayLogs.add(log.loggedAt);
    }
    final entitled = _ref.read(accessProvider) is Entitled;
    final limit = history.limitOn(today);
    final timer = NextLogTimer.at(
      now: now,
      day: today,
      boundary: boundary,
      window: settings.dayWindow,
      limit: limit,
      logs: todayLogs,
    );
    final daysLeft = history.current.quitDay.daysSince(today);
    var content = activityFor(
      timer: timer,
      entitled: entitled,
      enabled: settings.showLiveActivity,
      count: todayLogs.length,
      limit: limit,
      daysToGo: daysLeft < 0 ? 0 : daysLeft,
      lines: _pair,
    );
    // A new countdown takes a new pair of lines.
    if (content != null && content.next != _shown?.next) {
      _pair = pickLinePair(_ref.read(presenceRandomProvider), last: _pair);
      content = activityFor(
        timer: timer,
        entitled: entitled,
        enabled: settings.showLiveActivity,
        count: todayLogs.length,
        limit: limit,
        daysToGo: daysLeft < 0 ? 0 : daysLeft,
        lines: _pair,
      );
    }

    await _report(
      'Snapshot',
      _ref
          .read(presenceRepositoryProvider)
          .writeSnapshot(
            PresenceSnapshot.build(
              now: now,
              today: today,
              settings: settings,
              habit: habit,
              history: history,
              counts: counts,
              todayLogs: todayLogs,
              entitled: entitled,
              lastPair: _pair,
            ),
          ),
    );
    if (_disposed) return;
    await _showOrEnd(content);
  }

  Future<void> _showOrEnd(ActivityContent? content) async {
    if (_shownKnown && content == _shown) return;
    final repository = _ref.read(presenceRepositoryProvider);
    final sent = await _report(
      content == null ? 'End activity' : 'Show activity',
      content == null
          ? repository.endActivity()
          : repository.showActivity(content),
    );
    if (sent) {
      _shown = content;
      _shownKnown = true;
    }
  }

  Future<T> _value<T>(Future<Result<T>> call, T fallback) async {
    final result = await call;
    if (result case Success(:final value)) return value;
    _log('Read failed: ${(result as FailureResult<T>).failure}');
    return fallback;
  }

  Future<bool> _report(String what, Future<Result<void>> call) async {
    if (await call case FailureResult(:final failure)) {
      _log('$what failed: $failure');
      return false;
    }
    return true;
  }

  void _log(String message) => developer.log(message, name: 'PresenceSync');

  void dispose() {
    _disposed = true;
    unawaited(_queueSubscription.cancel());
  }
}

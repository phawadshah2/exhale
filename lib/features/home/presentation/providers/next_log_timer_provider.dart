import 'package:exhale/core/presentation/providers/clock_providers.dart';
import 'package:exhale/features/home/domain/pace_guide.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

/// The countdown to the next log on schedule today; null before today's first
/// log, when there is nothing to pace, or when the day window is not set.
final ProviderFamily<NextLogTimer?, int> nextLogTimerProvider = Provider
    .autoDispose
    .family<NextLogTimer?, int>((ref, habitId) {
      final window = ref.watch(currentSettingsProvider).dayWindow;
      if (window == null) return null;

      // The tick only rebuilds; a log between ticks must not count from a
      // second-old time.
      ref.watch(secondTickProvider);
      final now = ref.watch(clockProvider).now();
      final today = ref.watch(todayProvider);
      final boundary = ref.watch(dayBoundaryProvider);
      final progress = ref
          .watch(dayProgressProvider((habitId: habitId, day: today)))
          .value;
      final logs = ref
          .watch(logsForDayProvider((habitId: habitId, day: today)))
          .value;
      // The countdown waits for the day's first log.
      if (progress == null || logs == null || logs.isEmpty) return null;

      final times = [for (final log in logs) log.loggedAt];
      final guide = PaceGuide.compute(
        now: now,
        day: today,
        boundary: boundary,
        window: window,
        limit: progress.limit,
        countToday: progress.count,
        lastLogToday: times.lastOrNull,
        earlierLogsToday: times.isEmpty
            ? const []
            : times.sublist(0, times.length - 1),
      );
      return guide == null ? null : NextLogTimer(guide: guide, now: now);
    });

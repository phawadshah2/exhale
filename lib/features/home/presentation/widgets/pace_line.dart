import 'dart:async';

import 'package:exhale/core/presentation/providers/clock_providers.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/home/domain/pace_guide.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/settings/presentation/widgets/your_day_sheet.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The pace guide under the ring; a prompt until the day window is set.
class PaceLine extends ConsumerWidget {
  const PaceLine({required this.habitId, super.key});

  final int habitId;

  static int _ceilMinutes(Duration duration) =>
      (duration.inMicroseconds / Duration.microsecondsPerMinute).ceil();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final window = ref.watch(currentSettingsProvider).dayWindow;
    if (window == null) return const _SetYourDayPrompt();

    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider).now();
    final today = ref.watch(todayProvider);
    final boundary = ref.watch(dayBoundaryProvider);
    final progress = ref
        .watch(dayProgressProvider((habitId: habitId, day: today)))
        .value;
    if (progress == null) return const SizedBox.shrink();

    final latest = ref.watch(latestLogProvider(habitId)).value?.loggedAt;
    final guide = PaceGuide.compute(
      now: now,
      day: today,
      boundary: boundary,
      window: window,
      limit: progress.limit,
      countToday: progress.count,
      lastLogToday: latest != null && boundary.dayOf(latest) == today
          ? latest
          : null,
    );
    if (guide == null) return const SizedBox.shrink();

    final text = context.textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        spacing: 2,
        children: [
          Text(
            guide.next.isAfter(now)
                ? 'Next one on schedule in '
                      '${_ceilMinutes(guide.next.difference(now))} min'
                : "You're on schedule",
            textAlign: TextAlign.center,
            style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            'About one every ${_ceilMinutes(guide.pace)} min until bed',
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SetYourDayPrompt extends StatelessWidget {
  const _SetYourDayPrompt();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: InkWell(
        onTap: () {
          unawaited(HapticFeedback.selectionClick());
          unawaited(showYourDaySheet(context));
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Center(
            child: Text(
              'Set your day to get a pace guide',
              textAlign: TextAlign.center,
              style: context.textTheme.labelLarge?.copyWith(
                color: context.colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

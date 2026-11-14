import 'dart:async';

import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/home/domain/pace_guide.dart';
import 'package:exhale/features/home/presentation/providers/next_log_timer_provider.dart';
import 'package:exhale/features/home/presentation/widgets/draining_ring.dart';
import 'package:exhale/features/logs/presentation/logs_query.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The running countdown for the single habit, or null.
NextLogTimer? _runningTimer(WidgetRef ref) {
  final habitId = ref.watch(singleHabitIdProvider);
  final timer = habitId == null
      ? null
      : ref.watch(nextLogTimerProvider(habitId));
  return timer == null || timer.isPast ? null : timer;
}

/// Around the + button while the countdown runs: a draining ring. Fills the
/// button's bounds and paints outside them; touches go to the button.
class NextLogBadge extends ConsumerWidget {
  const NextLogBadge({required this.buttonSize, super.key});

  final double buttonSize;

  static const double ringInset = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = _runningTimer(ref);
    if (timer == null) return const SizedBox.shrink();

    final colors = context.colors;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -ringInset,
              top: -ringInset,
              child: DrainingRing(
                fraction: timer.fraction,
                restartKey: timer.guide.next,
                size: buttonSize + ringInset * 2,
                strokeWidth: 3,
                color: colors.primary,
                track: colors.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Above the + button while the countdown runs: the time left in hours and
/// minutes. Tapping it opens today's logs. A [Positioned] child of the shell's
/// body stack, so it can take touches above the tab bar.
class NextLogChip extends ConsumerWidget {
  const NextLogChip({required this.right, required this.aboveBar, super.key});

  /// From the screen's right edge to the + button's.
  final double right;

  /// From the tab bar's top to the chip's bottom.
  final double aboveBar;

  static const double _minTarget = 44;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = _runningTimer(ref);
    final habitId = ref.watch(singleHabitIdProvider);
    if (timer == null || habitId == null) return const SizedBox.shrink();

    final colors = context.colors;
    final left = AppFormat.hoursMinutes(timer.left);
    void open() {
      unawaited(HapticFeedback.selectionClick());
      final today = ref.read(todayProvider);
      openLogs(context, LogsQuery(habitId: habitId, from: today, to: today));
    }

    return Positioned(
      right: right,
      bottom: MediaQuery.paddingOf(context).bottom + aboveBar,
      child: Semantics(
        container: true,
        label: 'Next one on schedule in $left',
        button: true,
        onTapHint: "Open today's logs",
        onTap: open,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: open,
          behavior: HitTestBehavior.opaque,
          // The chip is shorter than a touch target; the spare reaches up and
          // left, so the chip stays where it was over the + button.
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: _minTarget,
              minHeight: _minTarget,
            ),
            child: Align(
              alignment: Alignment.bottomRight,
              widthFactor: 1,
              heightFactor: 1,
              child: DecoratedBox(
                key: const Key('next-log-chip'),
                decoration: ShapeDecoration(
                  color: colors.surfaceContainerHigh,
                  shape: StadiumBorder(
                    side: BorderSide(color: colors.outlineVariant),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  // Capped: it floats over the page, and the ring repeats it.
                  child: MediaQuery.withClampedTextScaling(
                    maxScaleFactor: 1.5,
                    child: Text(
                      left,
                      style: context.textTheme.labelLarge?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

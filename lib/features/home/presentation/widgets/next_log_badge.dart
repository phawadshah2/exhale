import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/home/presentation/providers/next_log_timer_provider.dart';
import 'package:exhale/features/home/presentation/widgets/draining_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Around the + button while the countdown runs: a draining ring and a chip in
/// whole minutes. Fills the button's bounds and paints outside them.
class NextLogBadge extends ConsumerWidget {
  const NextLogBadge({required this.buttonSize, super.key});

  final double buttonSize;

  static const double _ringInset = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitId = ref.watch(singleHabitIdProvider);
    final timer = habitId == null
        ? null
        : ref.watch(nextLogTimerProvider(habitId));
    if (timer == null || timer.isPast) return const SizedBox.shrink();

    final colors = context.colors;
    final minutes = AppFormat.minutes(timer.left);
    return Semantics(
      container: true,
      label: 'Next one on schedule in $minutes',
      excludeSemantics: true,
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -_ringInset,
              top: -_ringInset,
              child: DrainingRing(
                fraction: timer.fraction,
                restartKey: timer.guide.next,
                size: buttonSize + _ringInset * 2,
                strokeWidth: 3,
                color: colors.primary,
                track: colors.surfaceContainerHighest,
              ),
            ),
            Positioned(
              right: 0,
              bottom: buttonSize + _ringInset * 2,
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
                  child: Text(
                    minutes,
                    style: context.textTheme.labelLarge?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

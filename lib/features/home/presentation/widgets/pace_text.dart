import 'dart:async';

import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/home/presentation/providers/next_log_timer_provider.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/settings/presentation/widgets/your_day_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Under the ring: the pace for the rest of the day; a prompt until the day
/// window is set.
class PaceText extends ConsumerWidget {
  const PaceText({required this.habitId, super.key});

  final int habitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final window = ref.watch(currentSettingsProvider).dayWindow;
    if (window == null) return const _SetYourDayPrompt();

    final pace = ref.watch(
      nextLogTimerProvider(habitId).select(
        (timer) => timer != null && timer.showsPace
            ? AppFormat.hoursMinutes(timer.guide.pace)
            : null,
      ),
    );
    if (pace == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Text(
        'About one every $pace until bed',
        textAlign: TextAlign.center,
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
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

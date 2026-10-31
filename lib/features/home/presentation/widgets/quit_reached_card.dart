import 'dart:async';

import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/presentation/failure_message.dart';
import 'package:exhale/core/presentation/providers/clock_providers.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/app_snack_bar.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Offered under the ring once the plan reaches its quit date: stay at zero
/// or set a new goal.
class QuitReachedCard extends ConsumerWidget {
  const QuitReachedCard({required this.habitId, super.key});

  final int habitId;

  static const double _buttonHeight = 44;

  Future<void> _keepAtZero(BuildContext context, WidgetRef ref) async {
    final habit = ref.read(habitProvider(habitId));
    if (habit == null) return;
    unawaited(HapticFeedback.selectionClick());
    final now = ref.read(clockProvider).now();
    final result = await ref.read(updateHabitProvider)(
      habit.copyWith(quitAcknowledgedAt: () => now),
    );
    if (!context.mounted) return;
    if (result case FailureResult(:final failure)) {
      showAppSnackBar(
        context,
        message: failureMessage(failure),
        tone: SnackTone.danger,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = context.textTheme;
    final success = context.exhale.success.foreground;
    const buttonSize = Size.fromHeight(_buttonHeight);
    const buttonPadding = EdgeInsets.symmetric(horizontal: AppSpacing.sm);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: success.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Text('You reached your quit date', style: text.titleMedium),
          Text(
            "Your limit stays at zero. A slip still gets logged and doesn't "
            'reset your plan.',
            style: text.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: buttonSize,
                    padding: buttonPadding,
                  ),
                  onPressed: () => unawaited(_keepAtZero(context, ref)),
                  child: const Text('Keep at zero'),
                ),
              ),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: buttonSize,
                    padding: buttonPadding,
                  ),
                  onPressed: () =>
                      unawaited(context.push(AppRoutes.editPlanFor(habitId))),
                  child: const Text('New goal'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

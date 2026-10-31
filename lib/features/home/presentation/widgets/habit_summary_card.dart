import 'dart:async';

import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/presentation/providers/clock_providers.dart';
import 'package:exhale/core/theme/app_motion.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/status_badge.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/presentation/habit_icon.dart';
import 'package:exhale/features/habit/presentation/habit_wording.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:exhale/features/tracking/domain/entities/daily_progress.dart';
import 'package:exhale/features/tracking/domain/entities/limit_status.dart';
import 'package:exhale/features/tracking/presentation/limit_status_ui.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// One habit on the habit list: today's status and count. The whole card
/// opens that habit's dashboard.
class HabitSummaryCard extends ConsumerWidget {
  const HabitSummaryCard({required this.habitId, super.key});

  final int habitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracked = ref.watch(habitProvider(habitId));
    if (tracked == null) return const SizedBox.shrink();
    final habit = tracked.habit;
    final colors = context.colors;
    final text = context.textTheme;
    final today = ref.watch(todayProvider);
    final history = ref.watch(planHistoryProvider(habitId)).value;
    final progress = ref
        .watch(dayProgressProvider((habitId: habitId, day: today)))
        .value;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          unawaited(HapticFeedback.selectionClick());
          unawaited(context.push(AppRoutes.habitFor(habitId)));
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 14,
            children: [
              Row(
                spacing: AppSpacing.gutterSm,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      habit.kind.icon,
                      size: 22,
                      color: colors.primary,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(
                          habit.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleLarge,
                        ),
                        if (history != null)
                          Text(
                            habit.stageLine(history.current, today),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (progress != null)
                    StatusBadge(
                      label: progress.badgeLabel(habit),
                      colors: progress.status.colors(context),
                    ),
                  Icon(
                    AppIcons.chevronRight,
                    size: 18,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
              if (progress != null && history != null)
                _TodayPanel(
                  habitId: habitId,
                  habit: habit,
                  progress: progress,
                  history: history,
                  today: today,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayPanel extends ConsumerWidget {
  const _TodayPanel({
    required this.habitId,
    required this.habit,
    required this.progress,
    required this.history,
    required this.today,
  });

  final int habitId;
  final Habit habit;
  final DailyProgress progress;
  final PlanHistory history;
  final LogicalDay today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = context.textTheme;
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider).now();
    final latest = ref.watch(latestLogProvider(habitId)).value;
    final plan = history.planOn(today);
    final muted = text.bodySmall?.copyWith(color: colors.onSurfaceVariant);
    final since = latest == null ? null : now.difference(latest.loggedAt);

    final (remaining, remainingColor) = switch (progress.status) {
      LimitStatus.under when progress.limit == 0 => (
        'Keep it going',
        context.exhale.success.foreground,
      ),
      LimitStatus.under => ('${progress.remaining} left today', colors.primary),
      LimitStatus.at => ('Limit reached', context.exhale.warning.foreground),
      LimitStatus.over => (
        '${progress.overBy} over limit',
        context.exhale.danger.foreground,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: AppRadius.inner,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            spacing: AppSpacing.sm,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${progress.count}',
                        style: text.headlineSmall,
                      ),
                      TextSpan(
                        text:
                            ' / ${progress.limit} '
                            '${progress.limit == 1 ? habit.unit : habit.units}',
                        style: text.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                remaining,
                style: text.labelLarge?.copyWith(
                  color: remainingColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress.usedFraction),
            duration: AppMotion.fill,
            curve: AppMotion.fillCurve,
            builder: (context, used, _) => ClipRRect(
              borderRadius: AppRadius.pill,
              child: LinearProgressIndicator(
                value: used,
                minHeight: 8,
                backgroundColor: colors.surfaceContainerHighest,
                color: progress.status.barColor(context),
              ),
            ),
          ),
          Row(
            spacing: AppSpacing.sm,
            children: [
              Icon(AppIcons.clock, size: 13, color: colors.primary),
              Expanded(
                child: Text(
                  since == null
                      ? 'No logs yet'
                      : 'Last: ${AppFormat.ago(since)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: muted,
                ),
              ),
              if (!plan.isCompleteOn(today))
                Text(habit.nextTarget(plan, today), style: muted),
            ],
          ),
        ],
      ),
    );
  }
}

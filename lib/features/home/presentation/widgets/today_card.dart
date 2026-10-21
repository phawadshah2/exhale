import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/status_badge.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/presentation/habit_wording.dart';
import 'package:exhale/features/home/presentation/widgets/progress_ring.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/tracking/domain/entities/daily_progress.dart';
import 'package:exhale/features/tracking/domain/entities/limit_status.dart';
import 'package:exhale/features/tracking/domain/entities/smoke_log.dart';
import 'package:exhale/features/tracking/presentation/limit_status_ui.dart';
import 'package:flutter/material.dart';

class TodayCard extends StatelessWidget {
  const TodayCard({
    required this.progress,
    required this.plan,
    required this.today,
    required this.now,
    required this.latestLog,
    required this.isFirstDay,
    required this.habit,
    super.key,
  });

  final DailyProgress progress;
  final ReductionPlan plan;
  final LogicalDay today;
  final DateTime now;
  final SmokeLog? latestLog;
  final bool isFirstDay;
  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final statusColors = progress.status.colors(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(AppIcons.breath, color: colors.primary, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text("Today's Consumption", style: text.titleLarge),
                ),
                StatusBadge(
                  label: progress.badgeLabel(habit),
                  colors: statusColors,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            ProgressRing(
              progress: progress,
              child: _RingCentre(progress: progress, habit: habit),
            ),
            if (progress.count == 0) ...[
              const SizedBox(height: AppSpacing.md),
              _Note(
                label: progress.limit == 0
                    ? habit.freeLabel == null
                          ? 'None so far today.'
                          : '${habit.freeTitle} so far today.'
                    : 'No ${habit.units} logged today. Nice start.',
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Divider(color: colors.outlineVariant.withValues(alpha: 0.4)),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _InfoCell(
                    icon: AppIcons.clock,
                    label: 'Time since last',
                    value: _timeSinceLast(),
                  ),
                ),
                Expanded(
                  child: _InfoCell(
                    icon: AppIcons.trendDown,
                    label: 'Next target',
                    value: _nextTarget(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _timeSinceLast() {
    final latest = latestLog;
    if (latest == null) {
      return isFirstDay ? 'Plan started today' : 'No logs yet';
    }
    final elapsed = now.difference(latest.loggedAt);
    return AppFormat.elapsed(elapsed.isNegative ? Duration.zero : elapsed);
  }

  String _nextTarget() {
    final days = plan.daysUntilNextDrop(today);
    if (days == null) return habit.freeTitle;
    final next = plan.limitOn(plan.nextDropOn(today)!);
    if (next == 0) {
      return days == 1 ? 'Quit day tomorrow' : 'Quit day in ${days}d';
    }
    return days == 1 ? 'Drops to $next tomorrow' : 'Drops to $next in ${days}d';
  }
}

class _RingCentre extends StatelessWidget {
  const _RingCentre({required this.progress, required this.habit});

  final DailyProgress progress;
  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final colors = context.colors;
    final percent = progress.limit == 0
        ? null
        : (progress.count / progress.limit * 100).round();

    final (headline, caption, color) = switch (progress.status) {
      LimitStatus.under when progress.limit == 0 => (
        habit.freeDayTitle,
        'Keep it going',
        context.exhale.success.foreground,
      ),
      LimitStatus.under => (
        '${progress.remaining} left today',
        '$percent% of daily limit',
        colors.primary,
      ),
      LimitStatus.at => (
        'Limit reached',
        'You can still log.',
        context.exhale.warning.foreground,
      ),
      LimitStatus.over => (
        '${progress.overBy} over limit',
        percent == null ? 'Target is 0 today' : '$percent% of daily limit',
        context.exhale.danger.foreground,
      ),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          key: const Key('today-count'),
          TextSpan(
            children: [
              TextSpan(text: '${progress.count}', style: text.displayLarge),
              TextSpan(
                text: ' / ${progress.limit}',
                style: text.headlineMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Text(headline, style: text.titleLarge?.copyWith(color: color)),
        const SizedBox(height: 2),
        Text(
          caption,
          style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: ShapeDecoration(
        color: colors.surfaceContainerHigh,
        shape: StadiumBorder(
          side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.sm,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: context.exhale.success.foreground,
              shape: BoxShape.circle,
            ),
          ),
          Flexible(child: Text(label, style: context.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  const _InfoCell({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.sm,
      children: [
        Icon(icon, size: 20, color: colors.primary),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
              Text(value, style: text.titleMedium),
            ],
          ),
        ),
      ],
    );
  }
}

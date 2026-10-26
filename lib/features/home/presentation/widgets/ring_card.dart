import 'dart:async';

import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/presentation/providers/clock_providers.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/status_badge.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/presentation/habit_wording.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/home/presentation/providers/home_providers.dart';
import 'package:exhale/features/home/presentation/widgets/backward_pager.dart';
import 'package:exhale/features/home/presentation/widgets/day_triggers.dart';
import 'package:exhale/features/home/presentation/widgets/progress_ring.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:exhale/features/tracking/domain/entities/daily_progress.dart';
import 'package:exhale/features/tracking/domain/entities/limit_status.dart';
import 'package:exhale/features/tracking/presentation/limit_status_ui.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:exhale/features/tracking/presentation/trigger_ui.dart';
import 'package:exhale/features/tracking/presentation/widgets/day_detail_sheet.dart';
import 'package:exhale/features/tracking/presentation/widgets/log_editor_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The selected day's count against its limit. Swipe the ring, or use the
/// arrows, to move between days from [earliestDayProvider] up to today.
class RingCard extends ConsumerWidget {
  const RingCard({required this.habitId, super.key});

  final int habitId;

  static const double _ringSize = 220;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(planHistoryProvider(habitId)).value;
    final habit = ref.watch(habitProvider(habitId))?.habit;
    if (history == null || habit == null) {
      return const SizedBox(
        height: 360,
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    final colors = context.colors;
    final text = context.textTheme;
    final today = ref.watch(todayProvider);
    final earliest = ref.watch(earliestDayProvider(habitId));
    final day = ref.watch(ringShownDayProvider(habitId));
    final progress = ref
        .watch(dayProgressProvider((habitId: habitId, day: day)))
        .value;
    final isToday = day == today;
    final beforePlan = day.isBefore(history.firstDay);
    final page = today.daysSince(day);
    final pageCount = today.daysSince(earliest) + 1;
    final picker = ref.read(ringDayProvider(habitId).notifier);

    void step(int days) {
      unawaited(HapticFeedback.selectionClick());
      picker.pick(day.addDays(days));
    }

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
                  child: Text(
                    isToday
                        ? "Today's Consumption"
                        : AppFormat.weekdayDate(day),
                    style: text.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isToday)
                  _TodayChip(onTap: picker.showToday)
                else if (progress != null)
                  StatusBadge(
                    label: progress.badgeLabel(habit),
                    colors: progress.status.colors(context),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: _ringSize,
              child: Stack(
                children: [
                  BackwardPager(
                    pageCount: pageCount,
                    page: page,
                    onPageChanged: (index) =>
                        picker.pick(today.addDays(-index)),
                    itemBuilder: (context, index) => _DayRing(
                      habitId: habitId,
                      day: today.addDays(-index),
                      history: history,
                      habit: habit,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _StepButton(
                      icon: AppIcons.back,
                      tooltip: 'Previous day',
                      onPressed: page < pageCount - 1 ? () => step(-1) : null,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _StepButton(
                      icon: AppIcons.chevronRight,
                      tooltip: 'Next day',
                      onPressed: page > 0 ? () => step(1) : null,
                    ),
                  ),
                ],
              ),
            ),
            if (isToday && progress != null && progress.count == 0) ...[
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
            if (isToday)
              _TodayDetails(habitId: habitId, history: history, today: today)
            else if (beforePlan)
              _Details(
                left: (AppIcons.trendDown, 'Limit', 'None yet', null),
                right: (
                  AppIcons.calendar,
                  'Plan started',
                  AppFormat.monthDay(history.firstDay),
                  null,
                ),
              )
            else if (progress != null)
              _Details(
                left: (
                  AppIcons.trendDown,
                  'Limit that day',
                  '${progress.limit}',
                  null,
                ),
                right: (
                  AppIcons.checkCircle,
                  'Status',
                  progress.badgeLabel(habit),
                  null,
                ),
              ),
            if (!beforePlan) ...[
              const SizedBox(height: AppSpacing.md),
              DayTriggers(habitId: habitId, day: day),
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () =>
                        showDayDetailSheet(context, habitId: habitId, day: day),
                    icon: const Icon(AppIcons.clock, size: 18),
                    label: const Text('View logs'),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () =>
                        showLogEditorSheet(context, habitId: habitId, day: day),
                    icon: const Icon(AppIcons.add, size: 18),
                    label: const Text('Add missed log'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One page of the pager: the ring for [day].
class _DayRing extends ConsumerWidget {
  const _DayRing({
    required this.habitId,
    required this.day,
    required this.history,
    required this.habit,
  });

  final int habitId;
  final LogicalDay day;
  final PlanHistory history;
  final Habit habit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref
        .watch(dayProgressProvider((habitId: habitId, day: day)))
        .value;
    if (progress == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    final beforePlan = day.isBefore(history.firstDay);
    return Center(
      child: ProgressRing(
        progress: beforePlan ? null : progress,
        child: beforePlan
            ? _BeforePlanCentre(count: progress.count)
            : _RingCentre(
                progress: progress,
                habit: habit,
                isToday: day == ref.watch(todayProvider),
              ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 22),
      color: context.colors.onSurfaceVariant,
      disabledColor: context.colors.outlineVariant,
    );
  }
}

class _TodayChip extends StatelessWidget {
  const _TodayChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.primaryContainer.withValues(alpha: 0.16),
      shape: StadiumBorder(
        side: BorderSide(color: colors.primary.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gutterSm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Text(
                'Today',
                style: context.textTheme.labelLarge?.copyWith(
                  color: colors.primary,
                ),
              ),
              Icon(AppIcons.backToToday, size: 14, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayDetails extends ConsumerWidget {
  const _TodayDetails({
    required this.habitId,
    required this.history,
    required this.today,
  });

  final int habitId;
  final PlanHistory history;
  final LogicalDay today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider).now();
    final latest = ref.watch(latestLogProvider(habitId)).value;

    final String entry;
    final String? entryDetail;
    if (latest == null) {
      entry = today == history.firstDay ? 'Plan started today' : 'No logs yet';
      entryDetail = null;
    } else {
      final elapsed = now.difference(latest.loggedAt);
      final since = elapsed.isNegative ? Duration.zero : elapsed;
      entry = since.inMinutes < 1
          ? AppFormat.elapsed(since)
          : '${AppFormat.elapsed(since)} ago';
      entryDetail = AppFormat.time(latest.loggedAt);
    }

    final trigger = latest?.trigger;
    final note = latest?.note;
    return _Details(
      left: (AppIcons.clock, 'Last entry', entry, entryDetail),
      right: (
        AppIcons.trendDown,
        'Last trigger',
        trigger?.label ?? 'None',
        note == null || note.isEmpty ? null : note,
      ),
    );
  }
}

typedef _Cell = (IconData icon, String label, String value, String? detail);

class _Details extends StatelessWidget {
  const _Details({required this.left, required this.right});

  final _Cell left;
  final _Cell right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _InfoCell(cell: left)),
        Expanded(child: _InfoCell(cell: right)),
      ],
    );
  }
}

class _RingCentre extends StatelessWidget {
  const _RingCentre({
    required this.progress,
    required this.habit,
    required this.isToday,
  });

  final DailyProgress progress;
  final Habit habit;
  final bool isToday;

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
        isToday
            ? '${progress.remaining} left today'
            : '${progress.remaining} under limit',
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
        percent == null
            ? (isToday ? 'Target is 0 today' : 'Target was 0')
            : '$percent% of daily limit',
        context.exhale.danger.foreground,
      ),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          key: const Key('day-count'),
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

class _BeforePlanCentre extends StatelessWidget {
  const _BeforePlanCentre({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$count', key: const Key('day-count'), style: text.displayLarge),
        Text(
          'Before your plan',
          style: text.titleLarge?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(
          'No limit yet',
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
  const _InfoCell({required this.cell});

  final _Cell cell;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final (icon, label, value, detail) = cell;
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
              if (detail != null)
                Text(
                  detail,
                  style: text.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/failure_message.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/app_dialogs.dart';
import 'package:exhale/core/widgets/app_sheet.dart';
import 'package:exhale/core/widgets/status_badge.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:exhale/features/tracking/domain/entities/daily_progress.dart';
import 'package:exhale/features/tracking/domain/entities/habit_log.dart';
import 'package:exhale/features/tracking/presentation/limit_status_ui.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:exhale/features/tracking/presentation/trigger_ui.dart';
import 'package:exhale/features/tracking/presentation/widgets/log_editor_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showDayDetailSheet(
  BuildContext context, {
  required int habitId,
  required LogicalDay day,
}) => showAppDraggableSheet<void>(
  context,
  builder: (context, controller) =>
      DayDetailSheet(habitId: habitId, day: day, scrollController: controller),
);

class DayDetailSheet extends ConsumerWidget {
  const DayDetailSheet({
    required this.habitId,
    required this.day,
    required this.scrollController,
    super.key,
  });

  final int habitId;
  final LogicalDay day;
  final ScrollController scrollController;

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    HabitLog log,
  ) async {
    final confirmed = await showAppConfirm(
      context,
      title: 'Delete this log?',
      message:
          'The ${ref.read(habitProvider(habitId))?.habit.unit ?? 'log'} at '
          '${AppFormat.time(log.loggedAt)} will be removed '
          'from this day.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;
    final result = await ref.read(deleteHabitLogProvider)(log.id);
    if (result case FailureResult(:final failure) when context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failureMessage(failure))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref
        .watch(logsForDayProvider((habitId: habitId, day: day)))
        .value;
    final history = ref.watch(planHistoryProvider(habitId)).value;
    final habit = ref.watch(habitProvider(habitId))?.habit;
    final today = ref.watch(todayProvider);
    final text = context.textTheme;
    final colors = context.colors;
    final progress = logs == null || history == null
        ? null
        : DailyProgress(
            day: day,
            count: logs.length,
            limit: history.limitOn(day),
          );

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Day Detail', style: text.headlineSmall),
                      Text(
                        AppFormat.weekdayDate(day),
                        style: text.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (progress != null && habit != null)
          SliverPadding(
            padding: AppSpacing.page.copyWith(bottom: AppSpacing.md),
            sliver: SliverToBoxAdapter(
              child: _Summary(
                progress: progress,
                habit: habit,
                beforePlan: day.isBefore(history!.firstDay),
              ),
            ),
          ),
        if (logs == null)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator.adaptive()),
          )
        else if (logs.isEmpty)
          SliverPadding(
            padding: AppSpacing.page,
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Text(
                  'Nothing logged on this day.',
                  textAlign: TextAlign.center,
                  style: text.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: AppSpacing.page,
            sliver: SliverList.separated(
              itemCount: logs.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) => _LogTile(
                log: logs[index],
                dotColor: progress!.status.colors(context).foreground,
                onEdit: () => showLogEditorSheet(
                  context,
                  habitId: habitId,
                  day: day,
                  log: logs[index],
                ),
                onDelete: () => _confirmDelete(context, ref, logs[index]),
              ),
            ),
          ),
        SliverPadding(
          padding: AppSpacing.page.copyWith(
            top: AppSpacing.md,
            bottom: AppSpacing.xl,
          ),
          sliver: SliverToBoxAdapter(
            child: OutlinedButton.icon(
              onPressed: day.isAfter(today)
                  ? null
                  : () =>
                        showLogEditorSheet(context, habitId: habitId, day: day),
              icon: const Icon(AppIcons.add),
              label: const Text('Add missed log'),
            ),
          ),
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.progress,
    required this.habit,
    required this.beforePlan,
  });

  final DailyProgress progress;
  final Habit habit;

  /// A back-filled day with no limit.
  final bool beforePlan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: context.exhale.inset,
        borderRadius: AppRadius.inner,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              beforePlan
                  ? '${progress.count} logged'
                  : '${progress.count} of ${progress.limit} logged',
              style: context.textTheme.titleLarge,
            ),
          ),
          if (beforePlan)
            Text(
              'Before your plan',
              style: context.textTheme.labelLarge?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            )
          else
            StatusBadge(
              label: progress.badgeLabel(habit),
              colors: progress.status.colors(context),
            ),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({
    required this.log,
    required this.dotColor,
    required this.onEdit,
    required this.onDelete,
  });

  final HabitLog log;
  final Color dotColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final trigger = log.trigger;
    final note = log.note;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
      decoration: BoxDecoration(
        color: context.exhale.inset,
        borderRadius: AppRadius.inner,
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: AppFormat.time(log.loggedAt),
                        style: text.titleLarge,
                      ),
                      if (note != null)
                        TextSpan(
                          text: '  ·  $note',
                          style: text.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (trigger != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: ShapeDecoration(
                      color: colors.surfaceContainerHighest,
                      shape: const StadiumBorder(),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 4,
                      children: [
                        Icon(
                          trigger.icon,
                          size: 14,
                          color: colors.onSurfaceVariant,
                        ),
                        Text(trigger.label, style: text.labelMedium),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            onPressed: onEdit,
            icon: Icon(AppIcons.edit, color: colors.onSurfaceVariant),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: onDelete,
            icon: Icon(AppIcons.delete, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

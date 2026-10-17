import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/failure_message.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/status_badge.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:exhale/features/tracking/domain/entities/daily_progress.dart';
import 'package:exhale/features/tracking/domain/entities/smoke_log.dart';
import 'package:exhale/features/tracking/presentation/limit_status_ui.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:exhale/features/tracking/presentation/smoke_trigger_ui.dart';
import 'package:exhale/features/tracking/presentation/widgets/log_editor_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

Future<void> showDayDetailSheet(BuildContext context, LogicalDay day) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (context, controller) =>
            DayDetailSheet(day: day, scrollController: controller),
      ),
    );

class DayDetailSheet extends ConsumerWidget {
  const DayDetailSheet({
    required this.day,
    required this.scrollController,
    super.key,
  });

  final LogicalDay day;
  final ScrollController scrollController;

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SmokeLog log,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this log?'),
        content: Text(
          'The smoke at ${AppFormat.time(log.loggedAt)} will be '
          'removed from this day.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: context.exhale.danger.foreground,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await ref.read(deleteSmokeLogProvider)(log.id);
    if (result case FailureResult(:final failure) when context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failureMessage(failure))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(logsForDayProvider(day)).value;
    final history = ref.watch(planHistoryProvider).value;
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
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Symbols.close),
                  style: IconButton.styleFrom(
                    backgroundColor: colors.surfaceContainerHighest,
                    foregroundColor: colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (progress != null)
          SliverPadding(
            padding: AppSpacing.page.copyWith(bottom: AppSpacing.md),
            sliver: SliverToBoxAdapter(child: _Summary(progress: progress)),
          ),
        if (logs == null)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
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
                onEdit: () =>
                    showLogEditorSheet(context, day: day, log: logs[index]),
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
                  : () => showLogEditorSheet(context, day: day),
              icon: const Icon(Symbols.add),
              label: const Text('Add missed log'),
            ),
          ),
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.progress});

  final DailyProgress progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: AppRadius.inner,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${progress.count} of ${progress.limit} logged',
              style: context.textTheme.titleLarge,
            ),
          ),
          StatusBadge(
            label: progress.badgeLabel,
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

  final SmokeLog log;
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
        color: colors.surfaceContainerLow,
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
            icon: Icon(Symbols.edit, color: colors.onSurfaceVariant),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: onDelete,
            icon: Icon(Symbols.delete, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

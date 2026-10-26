import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:exhale/features/tracking/domain/entities/trigger_breakdown.dart';
import 'package:exhale/features/tracking/domain/services/progress_calculator.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:exhale/features/tracking/presentation/trigger_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The three most used triggers on [day], each with its count and share.
/// Rows open [onSelect] with their trigger when it is set.
class DayTriggers extends ConsumerWidget {
  const DayTriggers({
    required this.habitId,
    required this.day,
    this.onSelect,
    super.key,
  });

  final int habitId;
  final LogicalDay day;
  final ValueChanged<Trigger>? onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(logsForDayProvider((habitId: habitId, day: day)));
    final firstDay = ref.watch(planHistoryProvider(habitId)).value?.firstDay;
    final loaded = logs.value;
    if (loaded == null) return const SizedBox.shrink();

    final top = ProgressCalculator.triggerBreakdown(loaded).top(3);
    final isToday = day == ref.watch(todayProvider);
    if (top.isEmpty) {
      return loaded.isEmpty && day == firstDay
          ? const _Placeholder()
          : const SizedBox.shrink();
    }

    final text = context.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.sm,
      children: [
        Text(
          isToday ? "Today's triggers" : "That day's triggers",
          style: text.titleMedium,
        ),
        for (final share in top) _TriggerRow(share: share, onTap: onSelect),
      ],
    );
  }
}

class _TriggerRow extends StatelessWidget {
  const _TriggerRow({required this.share, required this.onTap});

  final TriggerShare share;
  final ValueChanged<Trigger>? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final percent = (share.fraction * 100).round();
    return InkWell(
      onTap: onTap == null ? null : () => onTap!(share.trigger),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          spacing: AppSpacing.sm,
          children: [
            Icon(share.trigger.icon, size: 20, color: colors.primary),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(share.trigger.label, style: text.bodyLarge),
                      ),
                      Text(
                        '${share.count} · $percent%',
                        style: text.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: share.fraction,
                      minHeight: 6,
                      color: colors.primary,
                      backgroundColor: colors.surfaceContainerHigh,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              AppIcons.chevronRight,
              size: 18,
              color: colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Text(
        'Triggers show up here as you log.',
        textAlign: TextAlign.center,
        style: context.textTheme.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

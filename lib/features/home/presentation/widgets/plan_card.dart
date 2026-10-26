import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/presentation/habit_wording.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:flutter/material.dart';

/// Progress from the start limit to the quit date, with the current and next
/// stage.
class PlanCard extends StatelessWidget {
  const PlanCard({
    required this.plan,
    required this.today,
    required this.habit,
    super.key,
  });

  final ReductionPlan plan;
  final LogicalDay today;
  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final stage = plan.stageOn(today);
    final next = stage == null
        ? (plan.hasStartedOn(today) ? null : plan.stages.first)
        : plan.stages.where((s) => s.number == stage.number + 1).firstOrNull;
    final daysToGo = plan.quitDay.daysSince(today);
    final percent = (plan.progressOn(today) * 100).floor();

    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your plan', style: text.titleMedium),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: plan.progressOn(today),
                minHeight: 8,
                backgroundColor: colors.surfaceContainerHighest,
                color: colors.primaryContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${plan.startLimit} a day',
                  style: text.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                Text(
                  '$percent% of the way',
                  style: text.bodySmall?.copyWith(color: colors.primary),
                ),
                Text(
                  '0',
                  style: text.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (stage != null)
              _Row(
                title: 'Stage ${stage.number} · ${stage.limit} a day (now)',
                detail: 'Until ${AppFormat.shortWeekdayDate(stage.endDay)}',
              ),
            if (next != null)
              _Row(
                title: 'Stage ${next.number} · ${next.limit} a day',
                detail: 'Starts ${AppFormat.shortWeekdayDate(next.startDay)}',
              ),
            _Row(
              title:
                  '${habit.freeTitle} from ${AppFormat.monthDay(plan.quitDay)}',
              detail: daysToGo > 0
                  ? '$daysToGo ${daysToGo == 1 ? 'day' : 'days'} to go'
                  : 'You reached your quit date',
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(title, style: text.titleSmall)),
          Text(
            detail,
            style: text.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

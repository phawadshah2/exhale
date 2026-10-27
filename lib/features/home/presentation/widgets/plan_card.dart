import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
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
    final quitDate = AppFormat.monthDay(plan.quitDay);

    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.md,
          children: [
            Row(
              children: [
                Expanded(child: Text('Your plan', style: text.titleMedium)),
                if (stage != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: ShapeDecoration(
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: colors.primary.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    child: Text(
                      'Stage ${stage.number} / ${plan.stageCount}',
                      style: text.labelMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            Column(
              spacing: 6,
              children: [
                Row(
                  children: [
                    Text(
                      AppFormat.monthDay(plan.startDay),
                      style: text.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '$percent% of the way',
                        textAlign: TextAlign.center,
                        style: text.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      AppFormat.monthDay(plan.quitDay),
                      style: text.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                ClipRRect(
                  borderRadius: AppRadius.pill,
                  child: LinearProgressIndicator(
                    value: plan.progressOn(today),
                    minHeight: 8,
                    backgroundColor: colors.surfaceContainerHighest,
                    color: colors.primaryContainer,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.gutterSm + 2),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                spacing: 14,
                children: [
                  if (stage != null)
                    _Row(
                      marker: _Marker.done,
                      title:
                          'Stage ${stage.number} · ${stage.limit} a day (now)',
                      detail:
                          'Since ${AppFormat.shortWeekdayDate(stage.startDay)}',
                      current: true,
                    ),
                  if (next != null)
                    _Row(
                      marker: _Marker.next,
                      title: 'Stage ${next.number} · ${next.limit} a day',
                      detail:
                          'Starts ${AppFormat.shortWeekdayDate(next.startDay)}',
                    ),
                  _Row(
                    marker: _Marker.finish,
                    title: '${habit.freeTitle} from $quitDate',
                    detail: daysToGo > 0
                        ? '$daysToGo ${daysToGo == 1 ? 'day' : 'days'} to go'
                        : 'You reached your quit date',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _Marker { done, next, finish }

class _Row extends StatelessWidget {
  const _Row({
    required this.marker,
    required this.title,
    required this.detail,
    this.current = false,
  });

  final _Marker marker;
  final String title;
  final String detail;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final filled = marker == _Marker.done;
    final icon = switch (marker) {
      _Marker.done => AppIcons.check,
      _Marker.next => AppIcons.forward,
      _Marker.finish => AppIcons.flag,
    };
    final tint = switch (marker) {
      _Marker.done => colors.onPrimaryContainer,
      _Marker.next => colors.onSurface,
      _Marker.finish => context.exhale.warning.foreground,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.gutterSm,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? colors.primaryContainer : null,
            border: filled
                ? null
                : Border.all(color: colors.outlineVariant, width: 1.5),
          ),
          child: Icon(icon, size: 14, color: tint),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text(
                title,
                style: text.titleSmall?.copyWith(
                  color: current ? colors.primary : null,
                  fontWeight: current ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
              Text(
                detail,
                style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

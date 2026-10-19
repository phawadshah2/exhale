import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:flutter/material.dart';

/// "Week 1 of 9 · Daily limit: 9" with a STAGE chip.
class StagePill extends StatelessWidget {
  const StagePill({required this.plan, required this.today, super.key});

  final ReductionPlan plan;
  final LogicalDay today;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final stage = plan.stageOn(today);

    final (label, chip) = !plan.hasStartedOn(today)
        ? (
            'Plan starts ${AppFormat.monthDay(plan.startDay)} · '
                'Daily limit: ${plan.startLimit}',
            'SOON',
          )
        : stage == null
        ? ('Smoke-free since ${AppFormat.monthDay(plan.quitDay)}', 'QUIT')
        : (
            'Stage ${stage.number} of ${plan.stageCount} · '
                'Daily limit: ${stage.limit}',
            'STAGE ${stage.number}',
          );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
      decoration: ShapeDecoration(
        color: colors.surfaceContainerLow,
        shape: StadiumBorder(
          side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: context.textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: ShapeDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.12),
              shape: StadiumBorder(
                side: BorderSide(
                  color: colors.primaryContainer.withValues(alpha: 0.4),
                ),
              ),
            ),
            child: Text(
              chip,
              style: context.textTheme.labelMedium?.copyWith(
                color: colors.primary,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

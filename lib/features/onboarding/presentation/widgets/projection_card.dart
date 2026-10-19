import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:flutter/material.dart';

class ProjectionCard extends StatelessWidget {
  const ProjectionCard({
    required this.plan,
    required this.cigarettePriceCents,
    required this.currencySymbol,
    super.key,
  });

  /// Null while the form is invalid.
  final ReductionPlan? plan;
  final double? cigarettePriceCents;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final highlight = TextStyle(
      color: context.exhale.success.foreground,
      fontWeight: FontWeight.w700,
    );

    final plan = this.plan;
    final price = cigarettePriceCents;
    final saved = plan == null || price == null
        ? null
        : AppFormat.money(
            plan.plannedReduction * price,
            symbol: currencySymbol,
            wholeUnits: true,
          );
    final body = plan == null
        ? const TextSpan(
            text: 'Pick a quit date at least 3 days after you start.',
          )
        : TextSpan(
            children: [
              TextSpan(text: '${paceSentence(plan)} '),
              const TextSpan(text: "You'll be smoke-free from "),
              TextSpan(
                text: AppFormat.fullDate(plan.quitDay),
                style: highlight.copyWith(color: colors.onSurface),
              ),
              const TextSpan(text: ". That's "),
              TextSpan(text: '${plan.plannedReduction}', style: highlight),
              const TextSpan(text: ' cigarettes avoided'),
              if (saved != null) ...[
                const TextSpan(text: ' and '),
                TextSpan(text: '~$saved', style: highlight),
                const TextSpan(text: ' saved'),
              ],
              const TextSpan(text: ' along the way.'),
            ],
          );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.06),
        borderRadius: AppRadius.card,
        border: Border.all(
          color: colors.primaryContainer.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.md,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primaryContainer.withValues(alpha: 0.12),
            ),
            child: Icon(AppIcons.sparkles, color: colors.primary),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.xs,
              children: [
                Text(
                  'TARGET PROJECTION',
                  style: text.labelLarge?.copyWith(
                    color: colors.primary,
                    letterSpacing: 1,
                  ),
                ),
                Text.rich(body, style: text.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Your limit drops by 1 about every 7 days." / "...by about 2 a day."
String paceSentence(ReductionPlan plan) {
  final days = plan.daysPerDrop;
  if (days < 1) {
    final perDay = (plan.startLimit / plan.totalDays).round();
    return 'Your limit drops by about $perDay a day.';
  }
  final rounded = days.round();
  return rounded == 1
      ? 'Your limit drops by 1 every day.'
      : 'Your limit drops by 1 about every $rounded days.';
}

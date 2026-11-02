import 'dart:async';
import 'dart:math' as math;

import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/plan/domain/services/plan_report.dart';
import 'package:exhale/features/plan/presentation/plan_copy.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// "The whole plan": four tiles, each out of its total, and what no plan would
/// have cost.
class PlanTotalsCard extends ConsumerWidget {
  const PlanTotalsCard({
    required this.habitId,
    required this.totals,
    required this.habit,
    super.key,
  });

  final int habitId;
  final PlanTotals totals;
  final Habit habit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symbol = ref.watch(currentSettingsProvider).currencySymbol;
    String money(double cents) =>
        AppFormat.money(math.max(0, cents), symbol: symbol);

    final saved = totals.savedCents;
    final savedOf = totals.savedOfCents;
    final without = totals.withoutPlanCents;
    final tiles = [
      _Tile(
        label: PlanCopy.used(habit),
        value: AppFormat.count(totals.used),
        of: AppFormat.count(totals.usedOf),
        fraction: _fraction(totals.used, totals.usedOf),
      ),
      _Tile(
        label: PlanCopy.avoided(habit),
        value: AppFormat.count(totals.avoided),
        of: AppFormat.count(totals.avoidedOf),
        fraction: _fraction(totals.avoided, totals.avoidedOf),
      ),
      if (habit.tracksCost && saved != null && savedOf != null)
        _Tile(
          label: PlanCopy.moneySaved,
          value: money(saved),
          of: money(savedOf),
          fraction: _fraction(saved, savedOf),
        )
      else if (habit.tracksCost)
        _Tile(
          label: PlanCopy.moneySaved,
          value: PlanCopy.noMoney,
          caption: PlanCopy.addPrice,
          fraction: 0,
          onTap: () {
            unawaited(HapticFeedback.selectionClick());
            unawaited(context.push(AppRoutes.editPlanFor(habitId)));
          },
        ),
      _Tile(
        label: PlanCopy.daysKept,
        value: AppFormat.count(totals.kept),
        of: AppFormat.count(totals.keptOf),
        fraction: _fraction(totals.kept, totals.keptOf),
      ),
    ];

    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.gutterSm,
          children: [
            Text(PlanCopy.wholePlan, style: context.textTheme.titleMedium),
            if (context.hasLargeText)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.sm,
                children: tiles,
              )
            else
              Column(
                spacing: AppSpacing.sm,
                children: [
                  for (var row = 0; row < tiles.length; row += 2)
                    if (row + 1 == tiles.length)
                      SizedBox(width: double.infinity, child: tiles[row])
                    else
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: AppSpacing.sm,
                          children: [
                            Expanded(child: tiles[row]),
                            Expanded(child: tiles[row + 1]),
                          ],
                        ),
                      ),
                ],
              ),
            Text(
              PlanCopy.withoutPlan(
                totals.withoutPlanUnits,
                habit,
                without == null ? null : money(without),
              ),
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static double _fraction(num value, num of) =>
      of <= 0 ? 0 : (value / of).clamp(0.0, 1.0);
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.value,
    required this.fraction,
    this.of,
    this.caption,
    this.onTap,
  });

  final String label;
  final String value;
  final String? of;
  final String? caption;
  final double fraction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final of = this.of;
    final caption = this.caption;
    return Semantics(
      button: onTap != null,
      label:
          '$label, $value'
          '${of == null ? '' : ' of $of'}'
          '${caption == null ? '' : '. $caption'}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.gutterSm),
          decoration: BoxDecoration(
            color: context.exhale.inset,
            borderRadius: AppRadius.inner,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: AppSpacing.xs,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.xs,
                children: [
                  Text(
                    label,
                    style: text.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      text: value,
                      style: text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      children: [
                        if (of != null)
                          TextSpan(
                            text: ' / $of',
                            style: text.labelLarge?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (caption != null)
                    Text(
                      caption,
                      style: text.bodySmall?.copyWith(color: colors.primary),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: ClipRRect(
                  borderRadius: AppRadius.pill,
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 4,
                    backgroundColor: colors.surfaceContainerHighest,
                    color: colors.primaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

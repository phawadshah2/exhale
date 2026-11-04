import 'dart:math' as math;

import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/fill_in.dart';
import 'package:exhale/features/plan/domain/services/plan_report.dart';
import 'package:exhale/features/plan/presentation/plan_copy.dart';
import 'package:exhale/features/plan/presentation/widgets/stage_days.dart';
import 'package:exhale/features/plan/presentation/widgets/stage_ring.dart';
import 'package:exhale/features/plan/presentation/widgets/stage_row.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The stage today is in, always open: its days, the key and how the stage
/// is going.
class CurrentStageCard extends ConsumerWidget {
  const CurrentStageCard({
    required this.report,
    required this.today,
    required this.nextLimit,
    super.key,
  });

  final StageReport report;
  final LogicalDay today;

  /// The limit after this stage; 0 on the last one.
  final int nextLimit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = context.textTheme;
    final symbol = ref.watch(currentSettingsProvider).currencySymbol;
    String money(double cents) =>
        AppFormat.money(math.max(0, cents), symbol: symbol);

    final saved = report.savedCents;
    final toSave = report.toSaveCents;
    final days = StageDays(report: report, today: today);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.gutterSm,
        children: [
          StageHeader(
            ring: ExcludeSemantics(child: StageRing(report: report, size: 56)),
            title: Row(
              spacing: 6,
              children: [
                Flexible(
                  child: Text(
                    PlanCopy.stage(report.stage.number),
                    style: text.titleSmall,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: AppRadius.pill,
                  ),
                  child: Text(
                    PlanCopy.now,
                    style: text.labelSmall?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            dates: PlanCopy.currentRange(report, today),
            money: saved == null || toSave == null
                ? null
                : StageMoney(
                    value: money(saved),
                    // A stage at the baseline has nothing to save of.
                    label: toSave > 0
                        ? PlanCopy.ofToSave(money(toSave))
                        : PlanCopy.saved,
                    color: context.exhale.success.foreground,
                  ),
          ),
          if (MediaQuery.disableAnimationsOf(context))
            days
          else
            FillIn(child: days),
          const _Key(),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.outlineVariant)),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 2,
                children: [
                  Text(
                    PlanCopy.usedAndOver(
                      report.used,
                      report.allowed,
                      report.daysOver,
                    ),
                    style: text.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    PlanCopy.drops(
                      nextLimit,
                      report.lastDay.daysSince(today) + 1,
                    ),
                    style: text.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      children: [
        _KeyEntry(PlanCopy.under, colors.primaryContainer),
        _KeyEntry(PlanCopy.atLimit, context.exhale.warning.solid),
        _KeyEntry(PlanCopy.over, context.exhale.danger.solid),
      ],
    );
  }
}

class _KeyEntry extends StatelessWidget {
  const _KeyEntry(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 6,
    children: [
      DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: const SizedBox.square(dimension: 8),
      ),
      Text(
        label,
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    ],
  );
}

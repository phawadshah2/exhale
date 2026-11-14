import 'package:exhale/core/theme/app_motion.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/paywall/domain/entities/plan_kind.dart';
import 'package:exhale/features/paywall/presentation/paywall_copy.dart';
import 'package:flutter/material.dart';

/// One plan: a radio, its name and line, its price and period. Its text
/// never changes with the selection.
class PlanCard extends StatelessWidget {
  const PlanCard({
    required this.plan,
    required this.price,
    required this.selected,
    required this.showTrialTag,
    required this.onTap,
    super.key,
  });

  static Key keyFor(PlanKind plan) => ValueKey('plan-card-${plan.name}');

  final PlanKind plan;
  final String price;
  final bool selected;

  /// "7 DAYS FREE" on the top edge; only Annual ever has it.
  final bool showTrialTag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final exhale = context.exhale;
    final text = context.textTheme;
    final (name, line, period) = switch (plan) {
      PlanKind.annual => (
        PaywallCopy.annual,
        PaywallCopy.annualLine,
        PaywallCopy.perYear,
      ),
      PlanKind.monthly => (
        PaywallCopy.monthlyName,
        PaywallCopy.monthlyLine,
        PaywallCopy.perMonth,
      ),
      PlanKind.lifetime => (
        PaywallCopy.lifetime,
        PaywallCopy.lifetimeLine,
        PaywallCopy.once,
      ),
    };
    final tag = showTrialTag && plan == PlanKind.annual;
    final muted = text.bodySmall?.copyWith(color: colors.onSurfaceVariant);
    final spokenLine = line.endsWith('.')
        ? line.substring(0, line.length - 1)
        : line;

    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      onTap: onTap,
      label: [
        name,
        spokenLine,
        '$price $period',
        if (tag) PaywallCopy.trialSpoken,
      ].join(', '),
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: AppMotion.swap,
                curve: AppMotion.swapCurve,
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color:
                      context.theme.cardTheme.color ??
                      colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected ? exhale.emphasis : colors.outlineVariant,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  spacing: 12,
                  children: [
                    AnimatedContainer(
                      duration: AppMotion.swap,
                      curve: AppMotion.swapCurve,
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? exhale.emphasis : colors.outline,
                          width: selected ? 6 : 2,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(line, style: muted),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          price,
                          style: text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(period, style: muted),
                      ],
                    ),
                  ],
                ),
              ),
              if (tag)
                Positioned(
                  top: -10,
                  right: 14,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: exhale.emphasis,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      child: Text(
                        PaywallCopy.trialTag,
                        style: text.labelSmall?.copyWith(
                          color: exhale.onEmphasis,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
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

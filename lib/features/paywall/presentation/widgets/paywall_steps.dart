import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/paywall/presentation/paywall_content.dart';
import 'package:flutter/material.dart';

IconData _iconFor(StepIcon icon) => switch (icon) {
  StepIcon.open => AppIcons.stepOpen,
  StepIcon.bell => AppIcons.stepRemind,
  StepIcon.card => AppIcons.stepCharge,
  StepIcon.renew => AppIcons.stepRenew,
  StepIcon.cancel => AppIcons.stepCancel,
  StepIcon.done => AppIcons.stepDone,
  StepIcon.forGood => AppIcons.stepForGood,
};

/// What happens after the button: down the page joined by a line, or, when
/// [row], one row of icons with a word under each.
class PaywallSteps extends StatelessWidget {
  const PaywallSteps({required this.steps, this.row = false, super.key});

  static const columnKey = Key('paywall-steps-column');
  static const rowKey = Key('paywall-steps-row');

  final List<PaywallStep> steps;
  final bool row;

  @override
  Widget build(BuildContext context) => row
      ? _StepRow(key: rowKey, steps: steps)
      : _StepColumn(key: columnKey, steps: steps);
}

class _Dot extends StatelessWidget {
  const _Dot({required this.icon, required this.size});

  final StepIcon icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final exhale = context.exhale;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: exhale.emphasis, shape: BoxShape.circle),
      child: Icon(_iconFor(icon), size: size * 0.5, color: exhale.onEmphasis),
    );
  }
}

class _StepColumn extends StatelessWidget {
  const _StepColumn({required this.steps, super.key});

  final List<PaywallStep> steps;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, step) in steps.indexed)
          MergeSemantics(
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 14,
                children: [
                  Column(
                    children: [
                      ExcludeSemantics(child: _Dot(icon: step.icon, size: 30)),
                      if (i < steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: colors.outline.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 4,
                        bottom: i < steps.length - 1 ? 12 : 0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 2,
                        children: [
                          Text(
                            step.title,
                            style: text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            step.body,
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
            ),
          ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.steps, super.key});

  final List<PaywallStep> steps;

  static const double _dot = 34;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    return Stack(
      children: [
        // The line runs from the first dot's centre to the last one's.
        Positioned(
          top: _dot / 2 - 1,
          left: 0,
          right: 0,
          child: FractionallySizedBox(
            widthFactor: (steps.length - 1) / steps.length,
            child: Container(height: 2, color: colors.outlineVariant),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final step in steps)
              Expanded(
                child: MergeSemantics(
                  child: Column(
                    spacing: 4,
                    children: [
                      ExcludeSemantics(
                        child: _Dot(icon: step.icon, size: _dot),
                      ),
                      Text(
                        step.rowTitle,
                        textAlign: TextAlign.center,
                        style: text.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        step.word,
                        textAlign: TextAlign.center,
                        style: text.labelMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:flutter/material.dart';

/// − value unit + control from the setup designs.
class NumberStepper extends StatelessWidget {
  const NumberStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.unit,
    required this.semanticLabel,
    this.caption,
    this.valueColor,
    super.key,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String unit;
  final String semanticLabel;
  final String? caption;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutterSm),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: AppRadius.inner,
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          _StepButton(
            icon: AppIcons.remove,
            tooltip: 'Decrease $semanticLabel',
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          Expanded(
            child: Semantics(
              label: semanticLabel,
              value: '$value $unit',
              child: ExcludeSemantics(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      spacing: 6,
                      children: [
                        Text(
                          '$value',
                          style: text.displayMedium?.copyWith(
                            color: valueColor,
                          ),
                        ),
                        Text(
                          unit,
                          style: text.titleMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    if (caption != null)
                      Text(
                        caption!,
                        style: text.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          _StepButton(
            icon: AppIcons.add,
            tooltip: 'Increase $semanticLabel',
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon),
      iconSize: 24,
      style: IconButton.styleFrom(
        fixedSize: const Size.square(52),
        backgroundColor: colors.surfaceContainerHighest,
        foregroundColor: colors.onSurface,
        disabledBackgroundColor: colors.surfaceContainerHigh,
      ),
    );
  }
}

import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/providers/onboarding_form_provider.dart';
import 'package:flutter/material.dart';

/// The daily amount as a row of up to [OnboardingFormState.maxDots] dots,
/// each standing for [unit] [units].
class DotsGrid extends StatelessWidget {
  const DotsGrid({
    required this.count,
    required this.unit,
    required this.units,
    super.key,
  });

  final int count;
  final int unit;
  final String units;

  static const double _gap = 7;

  @override
  Widget build(BuildContext context) {
    const slots = OnboardingFormState.maxDots;
    final exhale = context.exhale;
    return ExcludeSemantics(
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final size = ((constraints.maxWidth - _gap * (slots - 1)) / slots)
                  .floorToDouble();
              return Wrap(
                alignment: WrapAlignment.center,
                spacing: _gap,
                runSpacing: _gap,
                children: [
                  for (var i = 0; i < count; i++)
                    SizedBox.square(
                      dimension: size,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: exhale.emphasis,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          if (unit > 1) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              OnboardingCopy.dotCaption(unit, units),
              textAlign: TextAlign.center,
              style: context.textTheme.labelSmall?.copyWith(
                color: context.colors.outline,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

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
                    _Dot(
                      key: ValueKey(i),
                      index: i,
                      size: size,
                      color: exhale.emphasis,
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

/// Pops in when it first appears; the first row ripples in left to right.
class _Dot extends StatelessWidget {
  const _Dot({
    required this.index,
    required this.size,
    required this.color,
    super.key,
  });

  final int index;
  final double size;
  final Color color;

  static const Duration _pop = Duration(milliseconds: 320);
  static const Duration _stagger = Duration(milliseconds: 30);

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final delay = _stagger * index;
    final total = delay + _pop;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: still ? Duration.zero : total,
      curve: Interval(
        delay.inMilliseconds / total.inMilliseconds,
        1,
        curve: Curves.easeOutBack,
      ),
      builder: (context, t, child) =>
          Transform.scale(scale: t.clamp(0, 1.2), child: child),
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

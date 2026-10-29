import 'dart:async';

import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/glow_button.dart';
import 'package:exhale/core/widgets/smooth_switcher.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:exhale/features/onboarding/presentation/providers/onboarding_form_provider.dart';
import 'package:exhale/features/onboarding/presentation/widgets/amount_ruler.dart';
import 'package:exhale/features/onboarding/presentation/widgets/dots_grid.dart';
import 'package:exhale/features/onboarding/presentation/widgets/exhale_bubble.dart';
import 'package:exhale/features/onboarding/presentation/widgets/round_icon_button.dart';
import 'package:exhale/features/plan/domain/validation/plan_validation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Step 3: how much on a normal day, by − / +, the ruler or both.
class AmountStep extends ConsumerWidget {
  const AmountStep({super.key});

  static const int _min = PlanValidation.minStartLimit;
  static const int _max = PlanValidation.maxStartLimit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(onboardingFormProvider);
    final controller = ref.read(onboardingFormProvider.notifier);
    final habit = form.habit;
    final amount = form.startLimit;
    final reaction = OnboardingCopy.amountReaction(
      amount: amount,
      typical: habit.defaultDailyAmount,
    );

    void step(int delta) {
      unawaited(HapticFeedback.selectionClick());
      controller.setStartLimit(amount + delta);
    }

    return OnboardingStepFrame(
      footer: SizedBox(
        width: double.infinity,
        child: GlowButton(
          label: OnboardingCopy.continueButton,
          onPressed: () => OnboardingScope.of(context).next(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnboardingStepHeader(
            prompt: OnboardingCopy.amountPrompt,
            title: OnboardingCopy.amountTitle(habit.units),
          ),
          const SizedBox(height: AppSpacing.lg - 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 26,
            children: [
              RoundIconButton(
                icon: AppIcons.remove,
                label: OnboardingCopy.fewer,
                onTap: amount > _min ? () => step(-1) : null,
              ),
              Expanded(
                child: Semantics(
                  label: OnboardingCopy.perDay(habit.units),
                  value: '$amount',
                  child: ExcludeSemantics(
                    child: Column(
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '$amount',
                            style: context.textTheme.displayLarge?.copyWith(
                              fontSize: 64,
                              fontWeight: FontWeight.w700,
                              height: 1,
                              letterSpacing: -1.2,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          OnboardingCopy.perDay(habit.units),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              RoundIconButton(
                icon: AppIcons.add,
                label: OnboardingCopy.more,
                onTap: amount < _max ? () => step(1) : null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg - 2),
          AmountRuler(
            value: amount,
            min: _min,
            max: _max,
            onChanged: controller.setStartLimit,
          ),
          const SizedBox(height: AppSpacing.md + 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: DotsGrid(
              count: form.dotCount,
              unit: form.dotUnit,
              units: habit.units,
            ),
          ),
          const SizedBox(height: AppSpacing.md + 2),
          SmoothSwitcher(
            resize: true,
            child: ExhaleReply(key: ValueKey(reaction), text: reaction),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

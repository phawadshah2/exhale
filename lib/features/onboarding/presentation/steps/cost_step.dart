import 'dart:async';

import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/glow_button.dart';
import 'package:exhale/features/habit/domain/validation/habit_validation.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:exhale/features/onboarding/presentation/providers/onboarding_form_provider.dart';
import 'package:exhale/features/onboarding/presentation/widgets/currency_chip.dart';
import 'package:exhale/features/onboarding/presentation/widgets/exhale_bubble.dart';
import 'package:exhale/features/onboarding/presentation/widgets/round_icon_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Step 4: what it costs, as a month and a year. Only for habits that
/// track cost; the price can be skipped.
class CostStep extends ConsumerStatefulWidget {
  const CostStep({super.key});

  @override
  ConsumerState<CostStep> createState() => _CostStepState();
}

class _CostStepState extends ConsumerState<CostStep> {
  late final TextEditingController _price = TextEditingController(
    text: ref.read(onboardingFormProvider).priceText,
  );

  /// Set by Continue with an invalid price; cleared by the next edit.
  bool _showError = false;

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  void _continue() {
    if (ref.read(onboardingFormProvider).hasInvalidPrice) {
      unawaited(HapticFeedback.mediumImpact());
      setState(() => _showError = true);
      return;
    }
    OnboardingScope.of(context).next();
  }

  void _skip() {
    ref.read(onboardingFormProvider.notifier).skipPrice();
    _price.clear();
    setState(() => _showError = false);
    OnboardingScope.of(context).next();
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(onboardingFormProvider);
    final controller = ref.read(onboardingFormProvider.notifier);
    final colors = context.colors;
    final text = context.textTheme;
    final habit = form.habit;
    final container = habit.container;
    final monthly = form.monthlyCostCents;
    final yearly = form.yearlyCostCents;
    final showTotals =
        monthly != null && yearly != null && !form.hasInvalidPrice;
    final muted = text.bodySmall?.copyWith(color: colors.onSurfaceVariant);

    return OnboardingStepFrame(
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: GlowButton(
              label: OnboardingCopy.continueButton,
              onPressed: _continue,
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            minimumSize: const Size(44, 36),
            onPressed: _skip,
            child: Text(
              OnboardingCopy.skipPrice,
              style: text.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnboardingStepHeader(
            prompt: OnboardingCopy.costPrompt,
            title: container == null
                ? OnboardingCopy.costTitleUnit(habit.unit)
                : OnboardingCopy.costTitleContainer(container),
          ),
          const SizedBox(height: AppSpacing.md + 4),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    OnboardingCopy.priceOf(container ?? habit.unit),
                    style: muted,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    spacing: 10,
                    children: [
                      CurrencyChip(
                        symbol: form.currency,
                        onChanged: controller.setCurrency,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _price,
                          onChanged: (value) {
                            controller.setPriceText(value);
                            if (_showError) setState(() => _showError = false);
                          },
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp('[0-9.,]'),
                            ),
                          ],
                          style: text.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration.collapsed(
                            hintText: container == null ? '3.50' : '14.50',
                            hintStyle: text.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.outlineVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_showError && form.hasInvalidPrice) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      OnboardingCopy.invalidPrice,
                      style: text.bodySmall?.copyWith(color: colors.error),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (container != null) ...[
            const SizedBox(height: 10),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.gutterSm,
                ),
                child: Row(
                  spacing: 10,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            OnboardingCopy.perContainer(habit.units, container),
                            style: text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(OnboardingCopy.perContainerHint, style: muted),
                        ],
                      ),
                    ),
                    RoundIconButton(
                      icon: AppIcons.remove,
                      label: OnboardingCopy.fewer,
                      size: 34,
                      onTap: form.unitsPerContainer > 1
                          ? () => _stepUnits(form.unitsPerContainer - 1)
                          : null,
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 36),
                      child: Text(
                        '${form.unitsPerContainer}',
                        textAlign: TextAlign.center,
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    RoundIconButton(
                      icon: AppIcons.add,
                      label: OnboardingCopy.more,
                      size: 34,
                      onTap:
                          form.unitsPerContainer <
                              HabitValidation.maxUnitsPerContainer
                          ? () => _stepUnits(form.unitsPerContainer + 1)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
          AnimatedSize(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: showTotals
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),
                      Row(
                        spacing: 10,
                        children: [
                          Expanded(
                            child: _TotalTile(
                              label: OnboardingCopy.aMonth,
                              value: AppFormat.money(
                                monthly,
                                symbol: form.currency,
                                wholeUnits: true,
                              ),
                            ),
                          ),
                          Expanded(
                            child: _TotalTile(
                              label: OnboardingCopy.aYear,
                              value: AppFormat.money(
                                yearly,
                                symbol: form.currency,
                                wholeUnits: true,
                              ),
                              color: context.exhale.warning.foreground,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md - 2),
                      const ExhaleReply(text: OnboardingCopy.costReply),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  void _stepUnits(int value) {
    unawaited(HapticFeedback.selectionClick());
    ref.read(onboardingFormProvider.notifier).setUnitsPerContainer(value);
  }
}

class _TotalTile extends StatelessWidget {
  const _TotalTile({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: text.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/app_dialogs.dart';
import 'package:exhale/core/widgets/glow_button.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:exhale/features/onboarding/presentation/providers/onboarding_form_provider.dart';
import 'package:exhale/features/onboarding/presentation/widgets/taper_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Step 6: the taper to zero, the quit date, and the save.
class DealStep extends ConsumerWidget {
  const DealStep({super.key});

  Future<void> _pickDate(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(onboardingFormProvider.notifier);
    final picked = await showWheelPicker(
      context,
      title: OnboardingCopy.quitDate,
      mode: CupertinoDatePickerMode.date,
      initial: ref.read(onboardingFormProvider).quitDay.toLocalDate(),
      minimum: controller.earliestQuitDay.toLocalDate(),
    );
    if (picked != null) controller.setQuitDay(LogicalDay.fromDate(picked));
  }

  Future<void> _shake(BuildContext context, WidgetRef ref) async {
    unawaited(HapticFeedback.mediumImpact());
    final saved = await ref.read(onboardingFormProvider.notifier).submit();
    if (saved && context.mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(onboardingFormProvider);
    final controller = ref.read(onboardingFormProvider.notifier);
    final colors = context.colors;
    final text = context.textTheme;
    final plan = form.preview;
    final yearly = form.yearlyCostCents;
    final error = form.errorMessage;
    final muted = text.bodySmall?.copyWith(color: colors.onSurfaceVariant);

    return OnboardingStepFrame(
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: GlowButton(
              label: OnboardingCopy.dealButton,
              isBusy: form.isSubmitting,
              onPressed: plan == null ? null : () => _shake(context, ref),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              error,
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: colors.error),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            OnboardingCopy.dealFinePrint,
            textAlign: TextAlign.center,
            style: muted,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnboardingStepHeader(
            prompt: OnboardingCopy.dealPrompt,
            title: OnboardingCopy.dealTitle(
              form.startLimit,
              AppFormat.monthDay(form.quitDay),
            ),
          ),
          if (plan != null) ...[
            const SizedBox(height: AppSpacing.md + 2),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.gutterSm,
                ),
                child: TaperChart(plan: plan),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md - 2),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final preset in QuitPreset.values)
                _DealChip(
                  label: preset.label,
                  icon: preset == QuitPreset.suggested
                      ? AppIcons.sparkles
                      : null,
                  selected: form.quitPreset == preset,
                  onTap: () => controller.selectQuitPreset(preset),
                ),
              _DealChip(
                label: OnboardingCopy.pick,
                icon: AppIcons.calendar,
                selected: form.quitPreset == null,
                onTap: () => _pickDate(context, ref),
              ),
            ],
          ),
          if (form.isSteep) ...[
            const SizedBox(height: AppSpacing.gutterSm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.sm,
              children: [
                Icon(
                  AppIcons.stress,
                  size: 18,
                  color: context.exhale.warning.foreground,
                ),
                Expanded(
                  child: Text(
                    OnboardingCopy.steepWarning,
                    style: text.bodySmall,
                  ),
                ),
              ],
            ),
          ],
          if (plan != null) ...[
            const SizedBox(height: AppSpacing.md - 2),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: AppSpacing.gutterSm,
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      _Stat(
                        label: OnboardingCopy.tomorrow,
                        value: '${form.tomorrowLimit}',
                      ),
                      VerticalDivider(color: colors.outlineVariant),
                      _Stat(
                        label: OnboardingCopy.quitIn,
                        value: OnboardingCopy.days(plan.totalDays),
                      ),
                      if (yearly != null) ...[
                        VerticalDivider(color: colors.outlineVariant),
                        _Stat(
                          label: OnboardingCopy.backAYear,
                          value: AppFormat.money(
                            yearly,
                            symbol: form.currency,
                            wholeUnits: true,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.gutterSm),
            Text(
              OnboardingCopy.paceLine(form.paceMinutes),
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _DealChip extends StatelessWidget {
  const _DealChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = selected ? colors.primary : colors.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          unawaited(HapticFeedback.selectionClick());
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: ShapeDecoration(
            color: selected
                ? colors.primaryContainer.withValues(alpha: 0.14)
                : context.theme.cardTheme.color ?? colors.surfaceContainerLow,
            shape: StadiumBorder(
              side: BorderSide(
                color: selected ? colors.primary : colors.outlineVariant,
                width: selected ? 1.5 : 1,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 5,
            children: [
              if (icon != null) Icon(icon, size: 15, color: foreground),
              Text(
                label,
                style: context.textTheme.labelLarge?.copyWith(
                  color: foreground,
                  fontWeight: selected ? FontWeight.w600 : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return Expanded(
      child: Column(
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
            child: Text(
              value,
              style: text.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

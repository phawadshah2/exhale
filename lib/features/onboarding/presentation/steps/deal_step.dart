import 'dart:async';

import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_motion.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/app_dialogs.dart';
import 'package:exhale/core/widgets/glow_button.dart';
import 'package:exhale/core/widgets/smooth_switcher.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:exhale/features/onboarding/presentation/providers/onboarding_form_provider.dart';
import 'package:exhale/features/onboarding/presentation/widgets/onboarding_motion.dart';
import 'package:exhale/features/onboarding/presentation/widgets/taper_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Step 6: the taper to zero, the quit date, and the save.
class DealStep extends ConsumerStatefulWidget {
  const DealStep({super.key});

  /// How long the date sheet takes to slide away before the chart redraws.
  static const Duration sheetClose = Duration(milliseconds: 250);

  @override
  ConsumerState<DealStep> createState() => _DealStepState();
}

class _DealStepState extends ConsumerState<DealStep> {
  /// The chart waits for the sheet when the date came from Pick.
  Duration _chartDelay = Duration.zero;

  Future<void> _pickDate() async {
    final controller = ref.read(onboardingFormProvider.notifier);
    final picked = await showWheelPicker(
      context,
      title: OnboardingCopy.quitDate,
      mode: CupertinoDatePickerMode.date,
      initial: ref.read(onboardingFormProvider).quitDay.toLocalDate(),
      minimum: controller.earliestQuitDay.toLocalDate(),
    );
    if (picked == null || !mounted) return;
    setState(() => _chartDelay = DealStep.sheetClose);
    controller.setQuitDay(LogicalDay.fromDate(picked));
  }

  void _preset(QuitPreset preset) {
    setState(() => _chartDelay = Duration.zero);
    ref.read(onboardingFormProvider.notifier).selectQuitPreset(preset);
  }

  Future<void> _shake() async {
    unawaited(HapticFeedback.mediumImpact());
    final saved = await ref.read(onboardingFormProvider.notifier).submit();
    if (saved && mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(onboardingFormProvider);
    final colors = context.colors;
    final text = context.textTheme;
    final plan = form.preview;
    final yearly = form.yearlyCostCents;
    final error = form.errorMessage;
    final muted = text.bodySmall?.copyWith(color: colors.onSurfaceVariant);

    return OnboardingStepFrame(
      button: GlowButton(
        label: OnboardingCopy.dealButton,
        isBusy: form.isSubmitting,
        onPressed: plan == null ? null : _shake,
      ),
      below: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.sm,
          children: [
            if (error != null)
              Text(
                error,
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(color: colors.error),
              ),
            Text(
              OnboardingCopy.dealFinePrint,
              textAlign: TextAlign.center,
              style: muted,
            ),
          ],
        ),
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
            StepReveal(
              index: 2,
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.gutterSm,
                  ),
                  child: TaperChart(plan: plan, delay: _chartDelay),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md - 2),
          StepReveal(
            index: 3,
            child: Wrap(
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
                    onTap: () => _preset(preset),
                  ),
                _DealChip(
                  label: OnboardingCopy.pick,
                  icon: AppIcons.calendar,
                  selected: form.quitPreset == null,
                  onTap: _pickDate,
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: AppMotion.swap,
            curve: AppMotion.swapCurve,
            alignment: Alignment.topCenter,
            child: form.isSteep
                ? Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.gutterSm),
                    child: Row(
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
                  )
                : const SizedBox(width: double.infinity),
          ),
          if (plan != null) ...[
            const SizedBox(height: AppSpacing.md - 2),
            StepReveal(
              index: 4,
              child: Card(
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
                          value: form.tomorrowLimit,
                          format: (n) => '$n',
                        ),
                        VerticalDivider(color: colors.outlineVariant),
                        _Stat(
                          label: OnboardingCopy.quitIn,
                          value: plan.totalDays,
                          format: OnboardingCopy.days,
                        ),
                        if (yearly != null) ...[
                          VerticalDivider(color: colors.outlineVariant),
                          _Stat(
                            label: OnboardingCopy.backAYear,
                            value: yearly,
                            format: (cents) => AppFormat.money(
                              cents,
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
            ),
            const SizedBox(height: AppSpacing.gutterSm),
            StepReveal(
              index: 5,
              child: SmoothSwitcher(
                resize: true,
                child: Text(
                  OnboardingCopy.paceLine(form.paceMinutes),
                  key: ValueKey(form.paceMinutes),
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
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
    final pick = SelectionColors.of(context);
    final foreground = selected ? pick.foreground : context.colors.onSurface;
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
        child: PressScale(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: ShapeDecoration(
              color: selected ? pick.fill : pick.idleFill,
              shape: StadiumBorder(
                side: BorderSide(
                  color: selected ? pick.line : pick.idleLine,
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
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.format});

  final String label;
  final int value;
  final String Function(int value) format;

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
            child: CountTo(
              value: value,
              builder: (context, shown) => Text(
                format(shown),
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

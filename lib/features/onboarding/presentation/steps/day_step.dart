import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/glow_button.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:exhale/features/onboarding/presentation/providers/onboarding_form_provider.dart';
import 'package:exhale/features/settings/presentation/widgets/day_window_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Step 5: when the day runs, so the limit can be paced across it.
class DayStep extends ConsumerWidget {
  const DayStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final window = ref.watch(onboardingFormProvider.select((s) => s.dayWindow));
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
          const OnboardingStepHeader(
            prompt: OnboardingCopy.dayPrompt,
            title: OnboardingCopy.dayTitle,
          ),
          const SizedBox(height: AppSpacing.md),
          DayWindowPicker(
            window: window,
            onChanged: (value) => ref
                .read(onboardingFormProvider.notifier)
                .setDayWindow(
                  wakeMinute: value.wakeMinute,
                  bedMinute: value.bedMinute,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            OnboardingCopy.dayNote,
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

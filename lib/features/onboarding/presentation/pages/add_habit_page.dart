import 'package:exhale/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:exhale/features/onboarding/presentation/providers/onboarding_form_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The onboarding steps for one more habit, each with its own form.
class AddHabitPage extends StatelessWidget {
  const AddHabitPage({super.key});

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      onboardingModeProvider.overrideWithValue(OnboardingMode.addHabit),
    ],
    child: const OnboardingPage(),
  );
}

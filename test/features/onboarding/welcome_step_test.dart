import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/steps/welcome_step.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/onboarding.dart';
import '../../helpers/pump_app.dart';

void main() {
  setUp(() => setUpTestDependencies(FixedClock(DateTime(2026, 10, 20, 9))));
  tearDown(InjectionContainer.reset);

  void expectEndState() {
    for (final line in [
      ...OnboardingCopy.excuses,
      ...OnboardingCopy.welcomeReplies,
      OnboardingCopy.welcomeTitle,
      OnboardingCopy.welcomeBody,
      OnboardingCopy.welcomeButton,
      OnboardingCopy.welcomeFinePrint,
    ]) {
      expect(find.text(line), findsOneWidget, reason: line);
    }
    expect(
      find.text('You · Tonight 11:48 PM', findRichText: true),
      findsOneWidget,
    );
    expect(find.text(OnboardingCopy.welcomeRead), findsOneWidget);
  }

  testWidgets('plays the chat, then shows the headline', (tester) async {
    await pumpOnboarding(tester);
    await tester.pump();
    expect(find.text(OnboardingCopy.welcomeTitle), findsNothing);

    await tester.pumpInSteps(WelcomeStep.duration);
    await tester.pumpAndSettle();

    expectEndState();
    expect(find.text('1/6'), findsOneWidget);
    expect(find.byIcon(AppIcons.back), findsNothing);

    await tester.disposeApp();
  });

  testWidgets('a tap skips to the end', (tester) async {
    await pumpOnboarding(tester);
    await tester.pump();

    await tester.tap(find.byType(WelcomeStep));
    await tester.pump();

    expectEndState();

    await tester.disposeApp();
  });

  testWidgets('with reduced motion it starts at the end', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await pumpOnboarding(tester);
    await tester.pump();

    expectEndState();

    await tester.disposeApp();
  });
}

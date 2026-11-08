import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/steps/chat_step.dart';
import 'package:exhale/features/onboarding/presentation/steps/welcome_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/onboarding.dart';
import '../../helpers/pump_app.dart';

void main() {
  setUp(() => setUpTestDependencies(FixedClock(DateTime(2026, 10, 20, 9))));
  tearDown(InjectionContainer.reset);

  Future<void> pumpWelcome(WidgetTester tester) async {
    reduceMotion(tester);
    await pumpOnboarding(tester);
    await tester.pumpAndSettle();
  }

  testWidgets('pitches the app with four rows and one button', (tester) async {
    await pumpWelcome(tester);

    expect(find.byType(WelcomeStep), findsOneWidget);
    expect(find.text(OnboardingCopy.brand), findsOneWidget);
    expect(labelled(OnboardingCopy.welcomeTitle), findsOneWidget);
    expect(find.text(OnboardingCopy.welcomeNegotiating), findsOneWidget);
    expect(find.text(OnboardingCopy.welcomeBody), findsOneWidget);
    for (final (title, body) in OnboardingCopy.welcomeRows) {
      expect(find.text(title), findsOneWidget);
      expect(find.text(body), findsOneWidget);
    }
    expect(find.text(OnboardingCopy.welcomeButton), findsOneWidget);
    expect(find.text(OnboardingCopy.welcomeFinePrint), findsOneWidget);
    expect(labelled('Back'), findsNothing);

    await tester.disposeApp();
  });

  testWidgets('under Reduce Motion the strike is drawn at once', (
    tester,
  ) async {
    await pumpWelcome(tester);

    final struck = find
        .ancestor(
          of: find.text(OnboardingCopy.welcomeNegotiating),
          matching: find.byType(Stack),
        )
        .first;
    final strike = tester.widget<Transform>(
      find.descendant(of: struck, matching: find.byType(Transform)),
    );
    expect(strike.transform.getRow(0).x, 1);

    await tester.disposeApp();
  });

  testWidgets("Let's talk opens the chat", (tester) async {
    await pumpWelcome(tester);

    await tester.tap(find.text(OnboardingCopy.welcomeButton));
    await settleChat(tester);

    expect(find.byType(ChatStep), findsOneWidget);
    expect(find.byType(WelcomeStep), findsNothing);

    await tester.disposeApp();
  });
}

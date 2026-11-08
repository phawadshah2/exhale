import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/steps/chat_step.dart';
import 'package:exhale/features/onboarding/presentation/steps/deal_step.dart';
import 'package:exhale/features/onboarding/presentation/steps/welcome_step.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/onboarding.dart';
import '../../helpers/pump_app.dart';

void main() {
  setUp(() => setUpTestDependencies(FixedClock(DateTime(2026, 10, 20, 9))));
  tearDown(InjectionContainer.reset);

  Finder back() => labelled('Back');

  testWidgets('a first run is the welcome, the chat and the plan', (
    tester,
  ) async {
    await pumpOnboardingChat(tester);
    expect(find.byType(ChatStep), findsOneWidget);
    expect(find.byType(WelcomeStep), findsNothing);
    expect(back(), findsNothing);
    expect(find.text('2/3'), findsNothing);

    await chatToPlan(tester);
    expect(find.byType(DealStep), findsOneWidget);
    expect(back(), findsOneWidget);
    expect(find.text('3/3'), findsNothing);

    await tester.disposeApp();
  });

  testWidgets('the welcome does not move on with a left swipe', (tester) async {
    reduceMotion(tester);
    await pumpOnboarding(tester);
    await tester.pumpAndSettle();

    await tester.fling(
      find.text(OnboardingCopy.welcomeBody),
      const Offset(-300, 0),
      1000,
    );
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeStep), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('a right swipe on the chat does not return to the welcome', (
    tester,
  ) async {
    await pumpOnboardingChat(tester);

    await tester.fling(
      find.textContaining(OnboardingCopy.askWho),
      const Offset(300, 0),
      1000,
    );
    await tester.pumpAndSettle();

    expect(find.byType(ChatStep), findsOneWidget);
    expect(find.byType(WelcomeStep), findsNothing);

    await tester.disposeApp();
  });

  testWidgets('Back on the plan returns to the chat with its answers', (
    tester,
  ) async {
    await pumpOnboardingChat(tester);
    await chatToPlan(tester);

    await tester.tap(back());
    await tester.pumpAndSettle();

    expect(find.byType(ChatStep), findsOneWidget);
    expect(find.byType(DealStep), findsNothing);
    expect(find.textContaining("That's everything, Alex."), findsOneWidget);

    await tester.disposeApp();
  });
}

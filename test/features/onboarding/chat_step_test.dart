import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/steps/chat_step.dart';
import 'package:exhale/features/onboarding/presentation/widgets/chat_widgets.dart';
import 'package:exhale/features/onboarding/presentation/widgets/chevron_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/onboarding.dart';
import '../../helpers/pump_app.dart';

void main() {
  setUp(() => setUpTestDependencies(FixedClock(DateTime(2026, 11, 8, 9))));
  tearDown(InjectionContainer.reset);

  // Reduce Motion keeps every line of the script under a second.
  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  Future<void> toChat(WidgetTester tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpOnboarding(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text(OnboardingCopy.welcomeButton));
    await settle(tester);
  }

  // Through the answers still in the dock: name, vaping, the default amount,
  // no price, the default day.
  Future<void> answerAll(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(TextField, OnboardingCopy.nameHint),
      'Alex',
    );
    await tester.tap(find.text(OnboardingCopy.send));
    await settle(tester);
    await tester.tap(find.text('Vaping'));
    await settle(tester);
    await tester.tap(find.text(OnboardingCopy.send));
    await settle(tester);
    await tester.tap(find.text(OnboardingCopy.skipPrice));
    await settle(tester);
    await tester.tap(find.text(OnboardingCopy.thatsMyDay));
    await settle(tester);
  }

  Finder seePlan() =>
      find.widgetWithText(ChevronButton, OnboardingCopy.chatSeePlan);
  Finder jump() => find.byWidgetPredicate(
    (widget) =>
        widget is Semantics &&
        widget.properties.label == OnboardingCopy.jumpToNewest,
  );

  testWidgets('the chat fills from the top, under the glass bar', (
    tester,
  ) async {
    await toChat(tester);

    final barBottom = tester
        .getBottomLeft(find.text(OnboardingCopy.chatIdle))
        .dy;
    final first = tester
        .getTopLeft(find.textContaining(OnboardingCopy.excuses.first))
        .dy;
    expect(first, greaterThan(barBottom));
    expect(first, lessThan(barBottom + 60));
    expect(find.byKey(ChatAvatar.onlineKey), findsOneWidget);
    expect(jump(), findsNothing);

    await tester.disposeApp();
  });

  testWidgets('See my plan waits for the day, then opens the plan', (
    tester,
  ) async {
    await toChat(tester);
    expect(tester.widget<ChevronButton>(seePlan()).onPressed, isNull);

    await answerAll(tester);

    final newest = tester
        .getBottomLeft(find.textContaining("That's everything, Alex."))
        .dy;
    expect(newest, lessThanOrEqualTo(tester.getTopLeft(seePlan()).dy));
    expect(tester.widget<ChevronButton>(seePlan()).onPressed, isNotNull);

    await tester.tap(seePlan());
    await tester.pumpAndSettle();
    expect(find.text(OnboardingCopy.dealHeadline), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('scrolling back offers a jump to the newest message', (
    tester,
  ) async {
    await toChat(tester);
    await answerAll(tester);

    await tester.drag(
      find.descendant(
        of: find.byType(ChatStep),
        matching: find.byType(ListView),
      ),
      const Offset(0, 600),
    );
    await tester.pumpAndSettle();
    expect(jump(), findsOneWidget);
    expect(
      find.textContaining("That's everything, Alex.").hitTestable(),
      findsNothing,
    );

    await tester.tap(jump());
    await tester.pumpAndSettle();
    expect(jump(), findsNothing);
    expect(
      find.textContaining("That's everything, Alex.").hitTestable(),
      findsOneWidget,
    );

    await tester.disposeApp();
  });
}

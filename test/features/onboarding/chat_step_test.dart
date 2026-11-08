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

  // Name, vaping at the default amount, no price, the default day.
  Future<void> answerAll(WidgetTester tester) async {
    await answerName(tester);
    await tester.tap(find.text('Vaping'));
    await settleChat(tester);
    await tester.tap(find.text(OnboardingCopy.aboutRight));
    await settleChat(tester);
    await tester.tap(find.text(OnboardingCopy.skipPrice));
    await settleChat(tester);
    await tester.tap(find.text(OnboardingCopy.thatsMyDay));
    await settleChat(tester);
  }

  Finder seePlan() =>
      find.widgetWithText(ChevronButton, OnboardingCopy.chatSeePlan);
  Finder jump() => labelled(OnboardingCopy.jumpToNewest);

  testWidgets('the chat fills from the top, under the glass bar', (
    tester,
  ) async {
    await pumpOnboardingChat(tester);

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
    await pumpOnboardingChat(tester);
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
    await pumpOnboardingChat(tester);
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

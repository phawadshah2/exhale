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
  Finder tagline(String line) =>
      find.descendant(of: find.byType(ChatTagline), matching: find.text(line));

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

  group('the tagline', () {
    testWidgets('reacts to each answer of a vaping run', (tester) async {
      await pumpOnboardingChat(tester);
      expect(tagline(OnboardingCopy.taglineExcuses), findsOneWidget);

      await answerName(tester);
      expect(
        tagline('Nice to meet you, Alex. Your excuses already have.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Vaping'));
      await settleChat(tester);
      expect(
        tagline('Vaping. Flavoured air with a monthly bill.'),
        findsOneWidget,
      );

      await tester.tap(find.text(OnboardingCopy.aboutRight));
      await settleChat(tester);
      expect(
        tagline('12 a day. Your lungs have filed a complaint.'),
        findsOneWidget,
      );

      await tester.tap(find.text('AED 10'));
      await settleChat(tester);
      expect(tagline('AED 10 a pod. Your wallet felt that.'), findsOneWidget);

      await tester.tap(find.text(OnboardingCopy.aboutRight));
      await settleChat(tester);
      expect(
        tagline("AED 1,460 a year. That's a holiday you inhaled."),
        findsOneWidget,
      );

      await tester.tap(find.text(OnboardingCopy.thatsMyDay));
      await settleChat(tester);
      expect(tagline(OnboardingCopy.taglineDay), findsOneWidget);
      expect(find.byType(ChatTagline), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets('answers a skipped name and a skipped price', (tester) async {
      await pumpOnboardingChat(tester);
      await tester.tap(find.text(OnboardingCopy.nameSkip));
      await settleChat(tester);
      expect(tagline(OnboardingCopy.taglineNameSkipped), findsOneWidget);

      await tester.tap(find.text('Vaping'));
      await settleChat(tester);
      await tester.tap(find.text(OnboardingCopy.aboutRight));
      await settleChat(tester);
      await tester.tap(find.text(OnboardingCopy.skipPrice));
      await settleChat(tester);
      expect(tagline(OnboardingCopy.taglinePriceSkipped), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets('has its own lines for a habit without nicotine', (
      tester,
    ) async {
      await pumpOnboardingChat(tester);
      await answerName(tester);
      await tester.tap(find.text('Caffeine'));
      await settleChat(tester);
      expect(
        tagline('Caffeine. Borrowed energy, paid back at 3 PM.'),
        findsOneWidget,
      );

      await tester.tap(find.text(OnboardingCopy.aboutRight));
      await settleChat(tester);
      expect(tagline('3 a day. Noted. Judged, slightly.'), findsOneWidget);

      await tester.tap(find.text('AED 4'));
      await settleChat(tester);
      expect(tagline('AED 4 each. Your wallet felt that.'), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets('is a live region with the current line', (tester) async {
      await pumpOnboardingChat(tester);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              (widget.properties.liveRegion ?? false) &&
              widget.properties.label == OnboardingCopy.taglineExcuses,
        ),
        findsOneWidget,
      );

      await tester.disposeApp();
    });

    Future<void> swap(WidgetTester tester, {required bool still}) async {
      Widget line(String text) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: still),
          child: Scaffold(body: ChatTagline(text)),
        ),
      );
      await tester.pumpWidget(line('One'));
      await tester.pumpWidget(line('Two'));
      await tester.pump(const Duration(milliseconds: 100));
    }

    Finder slides() => find.descendant(
      of: find.byType(ChatTagline),
      matching: find.byType(SlideTransition),
    );

    testWidgets('slides the old line up and the new one in', (tester) async {
      await swap(tester, still: false);
      expect(find.text('One'), findsOneWidget);
      expect(find.text('Two'), findsOneWidget);
      expect(
        tester.getCenter(find.text('One')).dy,
        lessThan(tester.getCenter(find.text('Two')).dy),
      );
      expect(slides(), findsNWidgets(2));

      await tester.pumpAndSettle();
      expect(find.text('One'), findsNothing);
      expect(find.text('Two'), findsOneWidget);
    });

    testWidgets('cross-fades without sliding under Reduce Motion', (
      tester,
    ) async {
      await swap(tester, still: true);
      expect(find.text('One'), findsOneWidget);
      expect(find.text('Two'), findsOneWidget);
      expect(slides(), findsNothing);

      await tester.pumpAndSettle();
      expect(find.text('One'), findsNothing);
    });
  });
}

import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/onboarding.dart';
import '../../helpers/pump_app.dart';

void main() {
  setUp(() => setUpTestDependencies(FixedClock(DateTime(2026, 11, 8, 9))));
  tearDown(InjectionContainer.reset);

  Finder nameField() => find.widgetWithText(TextField, OnboardingCopy.nameHint);

  group('name card', () {
    testWidgets('sends on the button and folds to its question', (
      tester,
    ) async {
      await pumpOnboardingChat(tester);
      expect(labelled(OnboardingCopy.cardName), findsOneWidget);

      await answerName(tester);

      expect(find.textContaining('Alex. Lovely name.'), findsOneWidget);
      expect(nameField(), findsNothing);
      expect(labelled(OnboardingCopy.cardName), findsNothing);
      expect(find.textContaining(OnboardingCopy.askWho), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets('sends on the keyboard and ignores a blank name', (
      tester,
    ) async {
      await pumpOnboardingChat(tester);

      await tester.enterText(nameField(), '   ');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await settleChat(tester);
      expect(nameField(), findsOneWidget);

      await tester.enterText(nameField(), 'Sam');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await settleChat(tester);
      expect(find.textContaining('Sam. Lovely name.'), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets("skips with I'd rather not say", (tester) async {
      await pumpOnboardingChat(tester);

      await tester.tap(find.text(OnboardingCopy.nameSkip));
      await settleChat(tester);

      expect(find.textContaining(OnboardingCopy.nameSkipReply), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets('tapping your answer reopens the card with it', (tester) async {
      await pumpOnboardingChat(tester);
      await answerName(tester);

      await tester.tap(find.textContaining('Alex').first);
      await settleChat(tester);

      expect(nameField(), findsOneWidget);
      expect(tester.widget<TextField>(nameField()).controller?.text, 'Alex');

      await tester.disposeApp();
    });
  });

  group('habit card', () {
    testWidgets('shows every habit in three rows', (tester) async {
      await pumpOnboardingChat(tester);
      await answerName(tester);

      expect(labelled(OnboardingCopy.cardHabit), findsOneWidget);
      double row(String label) => tester.getCenter(find.text(label)).dy;
      // Each row starts below the last; the wide test font wraps a row
      // the way large text does.
      expect(row('Smoking'), row('Vaping'));
      expect(row('Caffeine'), greaterThan(row('Nicotine pouches')));
      expect(row('Junk food'), greaterThan(row('Alcohol')));
      expect(row(OnboardingCopy.other), greaterThan(row('Alcohol')));
      expect(
        tester.getTopLeft(find.text('Caffeine')).dx,
        tester.getTopLeft(find.text('Vaping')).dx,
      );
      expect(
        tester.getTopLeft(find.text('Junk food')).dx,
        tester.getTopLeft(find.text('Vaping')).dx,
      );
      expect(
        tester.getSize(find.text('Vaping')).height,
        lessThan(
          tester.getSize(find.textContaining(OnboardingCopy.askWho)).height,
        ),
      );

      await tester.disposeApp();
    });

    testWidgets('Other asks what it is, and can go back', (tester) async {
      await pumpOnboardingChat(tester);
      await answerName(tester);

      await tester.tap(find.text(OnboardingCopy.other));
      await tester.pumpAndSettle();
      expect(find.text('Vaping'), findsNothing);
      expect(find.text(OnboardingCopy.customNameHint), findsOneWidget);

      await tester.tap(find.text(OnboardingCopy.backToList));
      await tester.pumpAndSettle();
      expect(find.text('Vaping').hitTestable(), findsOneWidget);

      await tester.tap(find.text(OnboardingCopy.other));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, OnboardingCopy.customNameHint),
        'Gaming',
      );
      await tester.tap(labelled(OnboardingCopy.sendHabit));
      await settleChat(tester);

      expect(find.textContaining('Gaming'), findsOneWidget);
      expect(labelled(OnboardingCopy.cardAmount), findsOneWidget);

      await tester.disposeApp();
    });
  });

  group('amount card', () {
    testWidgets('steps the amount and sends it', (tester) async {
      await pumpOnboardingChat(tester);
      await answerName(tester);
      await tester.tap(find.text('Vaping'));
      await settleChat(tester);

      expect(labelled(OnboardingCopy.cardAmount), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('sessions a day'), findsOneWidget);

      await tester.tap(labelled(OnboardingCopy.more));
      await tester.pumpAndSettle();
      expect(find.text('13'), findsOneWidget);

      for (var i = 0; i < 12; i++) {
        await tester.tap(labelled(OnboardingCopy.fewer));
        await tester.pumpAndSettle();
      }
      expect(find.text('1'), findsOneWidget);
      final fewer = tester.widget<Semantics>(labelled(OnboardingCopy.fewer));
      expect(fewer.properties.enabled, isFalse);

      await tester.tap(find.text(OnboardingCopy.aboutRight));
      await settleChat(tester);

      expect(find.textContaining('1 a day'), findsOneWidget);
      expect(labelled(OnboardingCopy.cardAmount), findsNothing);

      await tester.disposeApp();
    });
  });
}

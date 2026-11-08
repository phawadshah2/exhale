import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/widgets/currency_chip.dart';
import 'package:exhale/features/settings/domain/entities/currency_choices.dart';
import 'package:flutter/cupertino.dart';
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

  // Name, vaping at 12 a day: the price card is open.
  Future<void> toPrice(WidgetTester tester) async {
    await pumpOnboardingChat(tester);
    await answerName(tester);
    await tester.tap(find.text('Vaping'));
    await settleChat(tester);
    await tester.tap(find.text(OnboardingCopy.aboutRight));
    await settleChat(tester);
  }

  Finder field(String hint) => find.widgetWithText(TextField, hint);

  bool enabled(WidgetTester tester, String label) =>
      tester.widget<Semantics>(labelled(label)).properties.enabled ?? true;

  group('price card', () {
    testWidgets('offers five scaled prices and Other', (tester) async {
      await toPrice(tester);

      expect(labelled(OnboardingCopy.cardPrice('pod')), findsOneWidget);
      for (final price in ['AED 5', 'AED 8', 'AED 10', 'AED 12', 'AED 15']) {
        expect(find.text(price), findsOneWidget);
      }
      expect(find.text(OnboardingCopy.other), findsOneWidget);

      await tester.tap(find.text('AED 10'));
      await settleChat(tester);

      expect(find.textContaining('AED 10'), findsOneWidget);
      expect(labelled(OnboardingCopy.cardPrice('pod')), findsNothing);
      expect(
        labelled(OnboardingCopy.cardPerPod('sessions', 'pod')),
        findsOneWidget,
      );

      await tester.disposeApp();
    });

    testWidgets('Other takes a typed price, not an invalid one', (
      tester,
    ) async {
      await toPrice(tester);

      await tester.tap(find.text(OnboardingCopy.other));
      await tester.pumpAndSettle();
      await tester.enterText(field(OnboardingCopy.priceHint), 'abc');
      await tester.tap(labelled(OnboardingCopy.sendPrice));
      await settleChat(tester);
      expect(field(OnboardingCopy.priceHint), findsOneWidget);
      expect(find.text(OnboardingCopy.invalidPrice), findsOneWidget);

      await tester.enterText(field(OnboardingCopy.priceHint), '7.50');
      await tester.tap(labelled(OnboardingCopy.sendPrice));
      await settleChat(tester);
      expect(find.textContaining('AED 7.50'), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets('Change picks another currency for the chips', (tester) async {
      await toPrice(tester);
      final start = CurrencyChoices.all.indexWhere((c) => c.symbol == 'AED');
      expect(find.text('AED · '), findsOneWidget);

      await tester.tap(find.text(OnboardingCopy.change));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(CupertinoPicker),
        const Offset(0, -CurrencyChip.itemExtent * 2),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Done'));
      await tester.pumpAndSettle();

      final picked = CurrencyChoices.all[start + 2].symbol;
      expect(find.text('$picked · '), findsOneWidget);
      expect(find.text('AED 10'), findsNothing);

      await tester.disposeApp();
    });

    testWidgets("I'd rather not know goes to the day", (tester) async {
      await toPrice(tester);

      await tester.tap(find.text(OnboardingCopy.skipPrice));
      await settleChat(tester);

      expect(labelled(OnboardingCopy.cardDay), findsOneWidget);

      await tester.disposeApp();
    });
  });

  testWidgets('the pod card steps by 5 up to 100, with how long one lasts', (
    tester,
  ) async {
    await toPrice(tester);
    await tester.tap(find.text('AED 10'));
    await settleChat(tester);

    expect(find.text('30'), findsOneWidget);
    expect(find.text('sessions a pod'), findsOneWidget);
    expect(find.text('About one pod every 2½ days'), findsOneWidget);

    await tester.tap(labelled(OnboardingCopy.fiveMore));
    await tester.pumpAndSettle();
    expect(find.text('35'), findsOneWidget);
    expect(find.text('About one pod every 3 days'), findsOneWidget);

    for (var i = 0; i < 13; i++) {
      await tester.tap(labelled(OnboardingCopy.fiveMore));
      await tester.pumpAndSettle();
    }
    expect(find.text('100'), findsOneWidget);
    expect(enabled(tester, OnboardingCopy.fiveMore), isFalse);

    await tester.tap(find.text(OnboardingCopy.aboutRight));
    await settleChat(tester);
    expect(find.textContaining('pod lasts 100.'), findsOneWidget);
    expect(find.text(OnboardingCopy.moneyCardTitle), findsOneWidget);
    expect(labelled(OnboardingCopy.cardDay), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('the day card steps by half hours within the awake minimum', (
    tester,
  ) async {
    await toPrice(tester);
    await tester.tap(find.text(OnboardingCopy.skipPrice));
    await settleChat(tester);

    expect(find.text('7:30 AM'), findsOneWidget);
    expect(find.text('11:30 PM'), findsOneWidget);
    expect(find.text('16 h awake · one every 1 h 20 min'), findsOneWidget);

    await tester.tap(labelled(OnboardingCopy.wakeLater));
    await tester.pumpAndSettle();
    expect(find.text('8:00 AM'), findsOneWidget);
    expect(
      find.text('15 h 30 min awake · one every 1 h 18 min'),
      findsOneWidget,
    );

    // 15 h 30 min down to the 4 h minimum is 23 half hours.
    for (var i = 0; i < 23; i++) {
      await tester.tap(labelled(OnboardingCopy.bedEarlier));
      await tester.pumpAndSettle();
    }
    expect(find.text('12:00 PM'), findsOneWidget);
    expect(enabled(tester, OnboardingCopy.bedEarlier), isFalse);
    expect(enabled(tester, OnboardingCopy.wakeLater), isFalse);
    expect(enabled(tester, OnboardingCopy.wakeEarlier), isTrue);

    await tester.tap(find.text(OnboardingCopy.thatsMyDay));
    await settleChat(tester);
    expect(find.textContaining('8:00 AM to 12:00 PM'), findsOneWidget);
    expect(find.textContaining("That's everything, Alex."), findsOneWidget);

    await tester.disposeApp();
  });
}

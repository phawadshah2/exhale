import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/providers/onboarding_form_provider.dart';
import 'package:exhale/features/onboarding/presentation/steps/cost_step.dart';
import 'package:exhale/features/onboarding/presentation/steps/welcome_step.dart';
import 'package:exhale/features/onboarding/presentation/widgets/currency_chip.dart';
import 'package:exhale/features/settings/domain/entities/currency_choices.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/onboarding.dart';
import '../../helpers/pump_app.dart';

void main() {
  setUp(() => setUpTestDependencies(FixedClock(DateTime(2026, 10, 20, 9))));
  tearDown(InjectionContainer.reset);

  Future<void> tapContinue(WidgetTester tester) async {
    await tester.tap(find.text(OnboardingCopy.continueButton).hitTestable());
    await tester.pumpAndSettle();
  }

  Future<void> toHabit(WidgetTester tester) async {
    await pumpOnboarding(tester);
    await tester.pump();
    await tester.tap(find.byType(WelcomeStep));
    await tester.pump();
    await tester.tap(find.text(OnboardingCopy.welcomeButton));
    await tester.pumpAndSettle();
  }

  Future<void> toCost(WidgetTester tester, Habit habit) async {
    await toHabit(tester);
    await tester.tap(find.text(habit.name));
    await tester.pumpAndSettle();
    await tapContinue(tester);
    await tapContinue(tester);
  }

  OnboardingFormController controller(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(CostStep)))
          .read(onboardingFormProvider.notifier);

  OnboardingFormState form(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(CostStep)))
          .read(onboardingFormProvider);

  Finder priceField() => find.descendant(
    of: find.byType(CostStep),
    matching: find.byType(TextField),
  );

  testWidgets('a pack price shows the month and year totals', (tester) async {
    await toCost(tester, Habit.smoking);
    expect(find.text('4/6'), findsOneWidget);
    expect(find.text(OnboardingCopy.costPrompt), findsOneWidget);
    expect(find.text('What does a pack cost?'), findsOneWidget);
    expect(find.text(OnboardingCopy.aMonth), findsNothing);
    expect(find.text(OnboardingCopy.costReply), findsNothing);

    controller(tester)
      ..setCurrency('£')
      ..setStartLimit(10);
    await tester.enterText(priceField(), '14.50');
    await tester.pumpAndSettle();

    expect(form(tester).unitsPerContainer, 20);
    expect(find.text(OnboardingCopy.aMonth), findsOneWidget);
    expect(find.text(OnboardingCopy.aYear), findsOneWidget);
    expect(
      find.text(AppFormat.money(21750, symbol: '£', wholeUnits: true)),
      findsOneWidget,
    );
    expect(
      find.text(AppFormat.money(264625, symbol: '£', wholeUnits: true)),
      findsOneWidget,
    );
    expect(find.text(OnboardingCopy.costReply), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('the units stepper changes the pack size', (tester) async {
    await toCost(tester, Habit.alcohol);

    expect(find.text('What does a bottle cost?'), findsOneWidget);
    expect(
      find.text(OnboardingCopy.perContainer('drinks', 'bottle')),
      findsOneWidget,
    );
    expect(find.text(OnboardingCopy.perContainerHint), findsOneWidget);

    final before = form(tester).unitsPerContainer;
    await tester.tap(
      find.descendant(
        of: find.byType(CostStep),
        matching: find.byIcon(AppIcons.add),
      ),
    );
    await tester.pump();
    expect(form(tester).unitsPerContainer, before + 1);
    expect(find.text('${before + 1}'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('a habit without a container asks for one unit', (tester) async {
    final habit = Habit.presets.firstWhere(
      (h) => h.tracksCost && !h.hasContainer,
    );
    await toCost(tester, habit);

    expect(find.text('What does one ${habit.unit} cost?'), findsOneWidget);
    expect(find.text(OnboardingCopy.perContainerHint), findsNothing);
    expect(
      find.descendant(
        of: find.byType(CostStep),
        matching: find.byIcon(AppIcons.add),
      ),
      findsNothing,
    );

    await tester.disposeApp();
  });

  testWidgets('an invalid price shows the message and stays', (tester) async {
    await toCost(tester, Habit.smoking);

    await tester.enterText(priceField(), '1.2.3');
    await tester.pump();
    expect(find.text(OnboardingCopy.invalidPrice), findsNothing);

    await tapContinue(tester);

    expect(find.text(OnboardingCopy.invalidPrice), findsOneWidget);
    expect(find.text('4/6'), findsOneWidget);

    await tester.enterText(priceField(), '1.2');
    await tester.pump();
    expect(find.text(OnboardingCopy.invalidPrice), findsNothing);

    await tester.disposeApp();
  });

  testWidgets("I'd rather not know clears the price and moves on", (
    tester,
  ) async {
    await toCost(tester, Habit.smoking);
    await tester.enterText(priceField(), '1.2.3');
    await tester.pump();

    await tester.tap(find.text(OnboardingCopy.skipPrice));
    await tester.pumpAndSettle();

    expect(find.text('5/6'), findsOneWidget);
    expect(find.text(OnboardingCopy.dayTitle), findsOneWidget);
    expect(
      ProviderScope.containerOf(tester.element(find.text('5/6')))
          .read(onboardingFormProvider)
          .priceText,
      isEmpty,
    );

    await tester.disposeApp();
  });

  testWidgets('the currency chip opens a wheel of currencies', (tester) async {
    await toCost(tester, Habit.smoking);
    final start = CurrencyChoices.all.indexWhere((c) => c.symbol == 'AED');
    expect(
      find.descendant(
        of: find.byType(CurrencyChip),
        matching: find.text('AED'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byType(CurrencyChip));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoPicker), findsOneWidget);

    await tester.drag(
      find.byType(CupertinoPicker),
      const Offset(0, -CurrencyChip.itemExtent * 2),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Done'));
    await tester.pumpAndSettle();

    final picked = CurrencyChoices.all[start + 2].symbol;
    expect(form(tester).currency, picked);
    expect(
      find.descendant(
        of: find.byType(CurrencyChip),
        matching: find.text(picked),
      ),
      findsOneWidget,
    );

    await tester.disposeApp();
  });

  testWidgets('Cost leaves the steps when the habit stops tracking cost', (
    tester,
  ) async {
    await toCost(tester, Habit.smoking);
    await tapContinue(tester);
    expect(find.text('5/6'), findsOneWidget);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byIcon(AppIcons.back));
      await tester.pumpAndSettle();
    }
    expect(find.text('2/6'), findsOneWidget);

    await tester.tap(find.text(Habit.socialMedia.name));
    await tester.pumpAndSettle();
    expect(find.text('2/5'), findsOneWidget);

    await tapContinue(tester);
    expect(find.text('3/5'), findsOneWidget);
    await tapContinue(tester);
    expect(find.text('4/5'), findsOneWidget);
    expect(find.text(OnboardingCopy.dayTitle), findsOneWidget);
    expect(find.byType(CostStep), findsNothing);

    await tester.tap(find.byIcon(AppIcons.back));
    await tester.pumpAndSettle();
    expect(find.text('3/5'), findsOneWidget);
    expect(
      find.text(OnboardingCopy.amountTitle(Habit.socialMedia.units)),
      findsOneWidget,
    );

    await tester.disposeApp();
  });
}

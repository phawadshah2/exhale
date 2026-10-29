import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/widgets/glow_button.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/steps/habit_step.dart';
import 'package:exhale/features/onboarding/presentation/steps/welcome_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/onboarding.dart';
import '../../helpers/pump_app.dart';

void main() {
  setUp(() => setUpTestDependencies(FixedClock(DateTime(2026, 10, 20, 9))));
  tearDown(InjectionContainer.reset);

  Future<void> toHabitStep(WidgetTester tester) async {
    await pumpOnboarding(tester);
    await tester.pump();
    await tester.tap(find.byType(WelcomeStep));
    await tester.pump();
    await tester.tap(find.text(OnboardingCopy.welcomeButton));
    await tester.pumpAndSettle();
  }

  Finder continueButton() => find.descendant(
    of: find.byType(HabitStep),
    matching: find.widgetWithText(GlowButton, OnboardingCopy.continueButton),
  );

  bool continueEnabled(WidgetTester tester) =>
      tester.widget<GlowButton>(continueButton()).onPressed != null;

  testWidgets('vaping is selected by default with its reply', (tester) async {
    await toHabitStep(tester);

    expect(find.text(OnboardingCopy.habitPrompt), findsOneWidget);
    expect(find.text(OnboardingCopy.habitLead), findsOneWidget);
    for (final habit in Habit.presets) {
      expect(find.text(habit.name), findsOneWidget);
    }
    expect(
      tester.getSemantics(find.bySemanticsLabel(Habit.vaping.name)),
      isSemantics(isButton: true, isSelected: true, hasTapAction: true),
    );
    expect(find.byIcon(AppIcons.checkCircle), findsOneWidget);
    expect(
      find.text(OnboardingCopy.habitReply(HabitKind.vaping)),
      findsOneWidget,
    );
    expect(continueEnabled(tester), isTrue);

    await tester.disposeApp();
  });

  testWidgets('tapping Smoking shows its reply', (tester) async {
    await toHabitStep(tester);

    await tester.tap(find.text(Habit.smoking.name));
    await tester.pumpAndSettle();

    expect(find.text('Classic. Retro, even.'), findsOneWidget);
    expect(
      find.text(OnboardingCopy.habitReply(HabitKind.vaping)),
      findsNothing,
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel(Habit.smoking.name)),
      isSemantics(isButton: true, isSelected: true, hasTapAction: true),
    );

    await tester.disposeApp();
  });

  testWidgets('Something else needs a name and a unit', (tester) async {
    await toHabitStep(tester);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.text(OnboardingCopy.somethingElse));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNWidgets(2));
    expect(
      find.text(OnboardingCopy.habitReply(HabitKind.custom)),
      findsOneWidget,
    );
    expect(continueEnabled(tester), isFalse);

    await tester.enterText(find.byType(TextField).first, 'Gaming');
    await tester.pump();
    expect(continueEnabled(tester), isFalse);

    await tester.enterText(find.byType(TextField).last, 'hour');
    await tester.pump();
    expect(continueEnabled(tester), isTrue);

    await tester.tap(continueButton());
    await tester.pumpAndSettle();

    expect(find.text('3/6'), findsOneWidget);
    expect(find.text(OnboardingCopy.amountTitle('hours')), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('Continue goes to the daily amount', (tester) async {
    await toHabitStep(tester);

    await tester.tap(continueButton());
    await tester.pumpAndSettle();

    expect(find.text('3/6'), findsOneWidget);
    expect(
      find.text(OnboardingCopy.amountTitle(Habit.vaping.units)),
      findsOneWidget,
    );

    await tester.disposeApp();
  });
}

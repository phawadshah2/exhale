import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/providers/onboarding_form_provider.dart';
import 'package:exhale/features/onboarding/presentation/steps/day_step.dart';
import 'package:exhale/features/onboarding/presentation/steps/welcome_step.dart';
import 'package:flutter/cupertino.dart';
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

  Future<void> toDay(WidgetTester tester, Habit habit) async {
    await pumpOnboarding(tester);
    await tester.pump();
    await tester.tap(find.byType(WelcomeStep));
    await tester.pump();
    await tester.tap(find.text(OnboardingCopy.welcomeButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(habit.name));
    await tester.pumpAndSettle();
    await tapContinue(tester);
    await tapContinue(tester);
    if (habit.tracksCost) await tapContinue(tester);
  }

  OnboardingFormState form(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(DayStep)))
          .read(onboardingFormProvider);

  testWidgets('the step shows Exhale, the title, the picker and the note', (
    tester,
  ) async {
    await toDay(tester, Habit.smoking);

    expect(find.text('5/6'), findsOneWidget);
    expect(find.text(OnboardingCopy.dayPrompt), findsOneWidget);
    expect(find.text(OnboardingCopy.dayTitle), findsOneWidget);
    expect(awakeLabel('16 h awake'), findsOneWidget);
    expect(find.text(OnboardingCopy.dayNote), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('Continue with the defaults goes to The deal', (tester) async {
    await toDay(tester, Habit.smoking);

    await tapContinue(tester);

    expect(find.byType(DayStep), findsNothing);
    expect(find.text(OnboardingCopy.dealPrompt), findsOneWidget);
    final state = ProviderScope.containerOf(
      tester.element(find.text(OnboardingCopy.dealPrompt)),
    ).read(onboardingFormProvider);
    expect(state.wakeMinute, 450);
    expect(state.bedMinute, 1410);

    await tester.disposeApp();
  });

  testWidgets('a bedtime of 1:00 AM is stored as minute 60', (tester) async {
    await toDay(tester, Habit.smoking);

    await tester.tap(find.text(OnboardingCopy.bedtime));
    await tester.pumpAndSettle();
    tester
        .widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker))
        .onDateTimeChanged(DateTime(2000, 1, 1, 1));
    await tester.pumpAndSettle();

    expect(form(tester).bedMinute, 60);
    expect(awakeLabel('17 h 30 min awake'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('a wake time that leaves under 4 h awake is refused', (
    tester,
  ) async {
    await toDay(tester, Habit.smoking);

    tester
        .widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker))
        .onDateTimeChanged(DateTime(2000, 1, 1, 23));
    await tester.pumpAndSettle();

    expect(form(tester).wakeMinute, 450);
    expect(awakeLabel('16 h awake'), findsOneWidget);

    await tester.disposeApp();
  });
}

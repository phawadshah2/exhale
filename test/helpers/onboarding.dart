import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/clock.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/theme/app_theme.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/domain/entities/habit_draft.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:exhale/features/habit/domain/usecases/start_tracking.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:exhale/features/onboarding/presentation/providers/onboarding_form_provider.dart';
import 'package:exhale/features/onboarding/presentation/steps/deal_step.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';

/// The day arc's time awake, which it speaks as one label ("16 h awake").
Finder awakeLabel(String label) => find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.label == label,
);

/// Pumps [OnboardingPage] alone on a tall phone, with a UAE locale.
Future<void> pumpOnboarding(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(1170, 2532)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [deviceRegionProvider.overrideWithValue('AE')],
      child: MaterialApp(theme: AppTheme.light, home: const OnboardingPage()),
    ),
  );
}

/// Pumps [OnboardingPage] as Change habit opens it, in place of a custom
/// habit so every preset is open (Vaping starts selected). The steps are the
/// habit, the amount, the cost for a habit with a price, and the plan.
/// Reduce Motion is on, so the plan settles.
Future<void> pumpChangeHabit(WidgetTester tester) async {
  reduceMotion(tester);
  // Every test that uses this runs in the morning, after the reset hour.
  final today = LogicalDay.fromDate(sl<Clock>().now());
  final started = await sl<StartTracking>()((
    habit: HabitDraft(
      habit: Habit.custom(name: 'Gaming', unit: 'game'),
    ),
    plan: PlanDraft(startDay: today, startLimit: 5, quitDay: today.addDays(35)),
  )) as Success<TrackedHabit>;
  tester.view
    ..physicalSize = const Size(1170, 2532)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        deviceRegionProvider.overrideWithValue('AE'),
        replacedHabitProvider.overrideWithValue(started.value),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const OnboardingPage()),
    ),
  );
  await tester.pumpAndSettle();
}

/// A widget whose [Semantics] label is [label], such as an icon-only button.
Finder labelled(String label) => find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.label == label,
);

/// Lets the chat script run: under Reduce Motion every line is well under a
/// second. The first pump builds anything that starts new timers.
Future<void> settleChat(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

/// Turns Reduce Motion on for the rest of the test. Otherwise an enabled
/// `ChevronButton` and the plan's dots loop, so `pumpAndSettle` never
/// returns on the welcome or the plan.
void reduceMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

/// The plan's main button, whose label names the pace and the quit date.
Finder planButton() => find.descendant(
  of: find.byType(DealStep),
  matching: find.byType(FilledButton),
);

/// Pumps onboarding with Reduce Motion on and opens the chat.
Future<void> pumpOnboardingChat(WidgetTester tester) async {
  reduceMotion(tester);
  await pumpOnboarding(tester);
  await tester.pumpAndSettle();
  await tester.tap(find.text(OnboardingCopy.welcomeButton));
  await settleChat(tester);
}

/// Answers the name card with [name].
Future<void> answerName(WidgetTester tester, [String name = 'Alex']) async {
  await tester.enterText(
    find.widgetWithText(TextField, OnboardingCopy.nameHint),
    name,
  );
  await tester.tap(labelled(OnboardingCopy.sendName));
  await settleChat(tester);
}

bool _shows(String text) => find.text(text).evaluate().isNotEmpty;

/// Answers the chat as Alex: [habit] at its usual amount, [price] typed
/// under Other (skipped when null), the usual count per container, the
/// default day. Then opens the plan, unless [open] is false.
Future<void> chatToPlan(
  WidgetTester tester, {
  String habit = 'Smoking',
  String? price,
  bool open = true,
}) async {
  await answerName(tester);
  await tester.tap(find.text(habit));
  await settleChat(tester);
  await tester.tap(find.text(OnboardingCopy.aboutRight));
  await settleChat(tester);
  if (_shows(OnboardingCopy.skipPrice)) {
    if (price == null) {
      await tester.tap(find.text(OnboardingCopy.skipPrice));
    } else {
      await tester.tap(find.text(OnboardingCopy.other));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, OnboardingCopy.priceHint),
        price,
      );
      await tester.tap(labelled(OnboardingCopy.sendPrice));
    }
    await settleChat(tester);
  }
  if (_shows(OnboardingCopy.aboutRight)) {
    await tester.tap(find.text(OnboardingCopy.aboutRight));
    await settleChat(tester);
  }
  await tester.tap(find.text(OnboardingCopy.thatsMyDay));
  await settleChat(tester);
  if (!open) return;
  await tester.tap(find.text(OnboardingCopy.chatSeePlan));
  await tester.pumpAndSettle();
}

/// The full app on a first run with Reduce Motion on, through the welcome
/// and the chat (see [chatToPlan]) to the plan.
Future<void> pumpAppToPlan(
  WidgetTester tester, {
  String habit = 'Smoking',
  String? price,
}) async {
  reduceMotion(tester);
  await tester.pumpAppPastSplash(height: 2400);
  await tester.tap(find.text(OnboardingCopy.welcomeButton));
  await settleChat(tester);
  await chatToPlan(tester, habit: habit, price: price);
}

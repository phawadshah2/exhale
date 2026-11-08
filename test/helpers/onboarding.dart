import 'package:exhale/core/theme/app_theme.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

/// Pumps onboarding with Reduce Motion on and opens the chat.
Future<void> pumpOnboardingChat(WidgetTester tester) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
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

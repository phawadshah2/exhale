import 'package:exhale/app/app.dart';
import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/home/presentation/pages/home_page.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:exhale/features/onboarding/presentation/pages/splash_page.dart';
import 'package:exhale/features/onboarding/presentation/widgets/typing_dots.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/pump_app.dart';

void main() {
  const intro = SplashPage.introDuration;
  const hold = SplashPage.holdDuration;
  const firstLaunch = SplashPage.firstLaunchDuration;

  setUp(() async {
    await setUpTestDependencies(FixedClock(DateTime(2026, 10, 16, 15, 42)));
    mockPackageInfo();
  });

  tearDown(InjectionContainer.reset);

  Future<void> seedReturningUser() => seedHabit(
    PlanDraft(
      startDay: LogicalDay(2026, 10, 16),
      startLimit: 5,
      quitDay: LogicalDay(2026, 10, 16).addDays(30),
    ),
  );

  Future<void> launch(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ProviderScope(child: ExhaleApp()));
  }

  Future<void> leaveSplash(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
  }

  void reduceMotion(WidgetTester tester) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }

  group('first launch', () {
    testWidgets('says we need to talk, then slides into Welcome', (
      tester,
    ) async {
      await launch(tester);
      await tester.pump();

      expect(find.text(OnboardingCopy.splashLine), findsOneWidget);
      expect(find.byType(TypingDots), findsOneWidget);
      expect(find.text('Exhale'), findsOneWidget);

      await tester.pump(firstLaunch - const Duration(milliseconds: 50));
      expect(find.byType(OnboardingPage), findsNothing);

      await tester.pump(const Duration(milliseconds: 50));
      await leaveSplash(tester);
      expect(find.byType(SplashPage), findsNothing);
      expect(find.text('1/6'), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets('a tap does not postpone leaving', (tester) async {
      await launch(tester);
      await tester.pump();

      await tester.tap(find.byType(SplashPage));
      await tester.pump(firstLaunch);
      await leaveSplash(tester);
      expect(find.text('1/6'), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets('with reduced motion it skips the dots', (tester) async {
      reduceMotion(tester);
      await launch(tester);
      await tester.pump();

      expect(find.text(OnboardingCopy.splashLine), findsOneWidget);
      expect(find.byType(TypingDots), findsNothing);

      await tester.pump(firstLaunch);
      await leaveSplash(tester);
      expect(find.text('1/6'), findsOneWidget);

      await tester.disposeApp();
    });
  });

  group('returning user', () {
    testWidgets('shows the full scene once the intro has played', (
      tester,
    ) async {
      await seedReturningUser();
      await launch(tester);
      await tester.pump(intro);

      expect(find.text('CALM MODE'), findsOneWidget);
      expect(find.text('Exhale'), findsOneWidget);
      expect(find.text('Breathe easier, one day at a time'), findsOneWidget);
      expect(find.text('v0.1.0'), findsOneWidget);
      expect(find.text(OnboardingCopy.splashLine), findsNothing);

      await tester.pump(hold);
      await leaveSplash(tester);
      await tester.disposeApp();
    });

    testWidgets('stays for the intro plus the hold, then routes home', (
      tester,
    ) async {
      await seedReturningUser();
      await launch(tester);
      await tester.pump(intro);
      await tester.pump(hold - const Duration(milliseconds: 50));
      expect(find.byType(SplashPage), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 50));
      await leaveSplash(tester);
      expect(find.byType(HomePage), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets('tapping replays the intro and postpones leaving', (
      tester,
    ) async {
      await seedReturningUser();
      await launch(tester);
      await tester.pump(intro);

      await tester.tap(find.byType(SplashPage));
      await tester.pump(hold);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(SplashPage), findsOneWidget);

      await tester.pump(intro + hold);
      await leaveSplash(tester);
      expect(find.byType(HomePage), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets('with reduced motion it skips the intro', (tester) async {
      reduceMotion(tester);
      await seedReturningUser();
      await launch(tester);
      await tester.pump();
      expect(find.text('Exhale'), findsOneWidget);

      await tester.pump(hold);
      await leaveSplash(tester);
      expect(find.byType(HomePage), findsOneWidget);

      await tester.disposeApp();
    });
  });
}

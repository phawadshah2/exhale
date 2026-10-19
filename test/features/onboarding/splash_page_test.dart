import 'package:exhale/app/app.dart';
import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/features/onboarding/presentation/pages/habit_picker_page.dart';
import 'package:exhale/features/onboarding/presentation/pages/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/pump_app.dart';

void main() {
  const intro = SplashPage.introDuration;
  const hold = SplashPage.holdDuration;

  setUp(() async {
    await setUpTestDependencies(FixedClock(DateTime(2026, 10, 16, 15, 42)));
    mockPackageInfo();
  });

  tearDown(InjectionContainer.reset);

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

  testWidgets('shows the full scene once the intro has played', (tester) async {
    await launch(tester);
    await tester.pump(intro);

    expect(find.text('CALM MODE'), findsOneWidget);
    expect(find.text('Exhale'), findsOneWidget);
    expect(find.text('Breathe easier, one day at a time'), findsOneWidget);
    expect(find.text('v0.1.0'), findsOneWidget);

    await tester.pump(hold);
    await leaveSplash(tester);
    await tester.disposeApp();
  });

  testWidgets('stays for the intro plus the hold, then routes to setup', (
    tester,
  ) async {
    await launch(tester);
    await tester.pump(intro);
    await tester.pump(hold - const Duration(milliseconds: 50));
    expect(find.byType(SplashPage), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 50));
    await leaveSplash(tester);
    expect(find.byType(HabitPickerPage), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('tapping replays the intro and postpones leaving', (
    tester,
  ) async {
    await launch(tester);
    await tester.pump(intro);

    await tester.tap(find.byType(SplashPage));
    await tester.pump(hold);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(SplashPage), findsOneWidget);

    await tester.pump(intro + hold);
    await leaveSplash(tester);
    expect(find.byType(HabitPickerPage), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('with reduced motion it skips the intro', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await launch(tester);
    await tester.pump();
    expect(find.text('Exhale'), findsOneWidget);

    await tester.pump(hold);
    await leaveSplash(tester);
    expect(find.byType(HabitPickerPage), findsOneWidget);

    await tester.disposeApp();
  });
}

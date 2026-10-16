import 'package:exhale/app/app.dart';
import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/features/onboarding/presentation/pages/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixed_clock.dart';
import 'test_database.dart';

/// Registers real dependencies on an in-memory database.
Future<void> setUpTestDependencies(FixedClock clock) =>
    InjectionContainer.setupDependencies(
      database: createTestDatabase(),
      clock: clock,
    );

extension PumpApp on WidgetTester {
  /// Launches the app and waits past the splash screen.
  Future<void> pumpAppPastSplash() async {
    view
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3;
    addTearDown(view.reset);
    await pumpWidget(const ProviderScope(child: ExhaleApp()));
    await pump(SplashPage.minimumDuration);
    await pump(const Duration(milliseconds: 100));
    await pumpAndSettle();
  }

  /// Scrolls [finder] into view, then taps it.
  Future<void> scrollAndTap(Finder finder) async {
    await ensureVisible(finder);
    await pumpAndSettle();
    await tap(finder);
    await pump();
  }

  /// Unmounts the app so stream subscriptions and timers are released.
  Future<void> disposeApp() async {
    await pumpWidget(const SizedBox.shrink());
    await pump(Duration.zero);
  }
}

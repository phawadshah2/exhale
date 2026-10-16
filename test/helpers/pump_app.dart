import 'package:exhale/app/app.dart';
import 'package:exhale/app/bootstrap.dart';
import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/features/onboarding/presentation/pages/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'fixed_clock.dart';
import 'test_database.dart';

/// Registers real dependencies on an in-memory database.
Future<void> setUpTestDependencies(FixedClock clock) =>
    InjectionContainer.setupDependencies(
      database: createTestDatabase(),
      clock: clock,
    );

void mockPackageInfo() => PackageInfo.setMockInitialValues(
  appName: 'Exhale',
  packageName: 'com.phawadshah.exhale',
  version: '0.1.0',
  buildNumber: '1',
  buildSignature: '',
);

extension PumpApp on WidgetTester {
  /// Launches the app and waits past the splash screen.
  Future<void> pumpAppPastSplash() async {
    view
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3;
    addTearDown(view.reset);
    mockPackageInfo();
    await pumpWidget(
      ProviderScope(
        overrides: await startupOverrides(),
        child: const ExhaleApp(),
      ),
    );
    await pump(SplashPage.introDuration + SplashPage.holdDuration);
    await pump(const Duration(milliseconds: 100));
    await pumpAndSettle();
  }

  /// Advances [duration] in 50 ms frames so chained animations play out.
  Future<void> pumpInSteps(Duration duration) async {
    const step = Duration(milliseconds: 50);
    for (var elapsed = Duration.zero; elapsed < duration; elapsed += step) {
      await pump(step);
    }
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

import 'package:exhale/app/app.dart';
import 'package:exhale/app/bootstrap.dart';
import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/features/onboarding/presentation/pages/splash_page.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/entities/theme_preference.dart';
import 'package:exhale/features/settings/domain/usecases/save_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixed_clock.dart';
import '../helpers/pump_app.dart';

void main() {
  setUp(() async {
    await setUpTestDependencies(FixedClock(DateTime(2026, 10, 16, 15, 42)));
    mockPackageInfo();
  });

  tearDown(InjectionContainer.reset);

  testWidgets('the very first frame uses the saved theme', (tester) async {
    await sl<SaveSettings>()(
      const AppSettings(themePreference: ThemePreference.light),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: await startupOverrides(),
        child: const ExhaleApp(),
      ),
    );

    final splash = tester.element(find.byType(SplashPage));
    expect(Theme.of(splash).brightness, Brightness.light);

    await tester.disposeApp();
  });
}

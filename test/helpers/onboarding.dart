import 'package:exhale/core/theme/app_theme.dart';
import 'package:exhale/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

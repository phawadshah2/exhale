import 'package:exhale/features/settings/presentation/providers/theme_mode_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemeModeController', () {
    // ProviderContainer.test() = a ProviderScope without widgets. It is
    // disposed automatically when the test ends.
    test('starts in dark mode, matching the designs', () {
      final container = ProviderContainer.test();

      expect(container.read(themeModeControllerProvider), ThemeMode.dark);
    });

    test('select updates the state', () {
      final container = ProviderContainer.test();

      container
          .read(themeModeControllerProvider.notifier)
          .select(ThemeMode.light);

      expect(container.read(themeModeControllerProvider), ThemeMode.light);
    });
  });
}

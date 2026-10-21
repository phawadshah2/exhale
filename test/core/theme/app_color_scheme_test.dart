import 'package:exhale/core/theme/app_color_scheme.dart';
import 'package:exhale/core/theme/app_palette.dart';
import 'package:exhale/core/theme/app_theme.dart';
import 'package:exhale/core/theme/exhale_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildColorScheme', () {
    // Hex values copied from design/obsidian_sanctuary/DESIGN.md. If a
    // Flutter upgrade changes the seed algorithm, this test catches it.
    test('dark scheme reproduces the Stitch tokens', () {
      final dark = buildColorScheme(brightness: Brightness.dark);

      expect(dark.primary, const Color(0xFF57F1DB));
      expect(dark.primaryContainer, const Color(0xFF2DD4BF));
      expect(dark.secondary, const Color(0xFF4EDEA3));
      expect(dark.surface, const Color(0xFF0E141D));
      expect(dark.surfaceContainerLow, const Color(0xFF161C25));
      expect(dark.onSurface, const Color(0xFFDDE2F0));
      expect(dark.onSurfaceVariant, const Color(0xFFBACAC5));
    });

    test('brand seeds stay the solid fills in both modes', () {
      for (final brightness in Brightness.values) {
        final scheme = buildColorScheme(brightness: brightness);
        final status = ExhaleColors.fromScheme(scheme);

        expect(scheme.primaryContainer, AppPalette.eucalyptus);
        expect(status.success.solid, AppPalette.emerald);
        expect(status.warning.solid, AppPalette.amber);
        // Coral is nudged by the algorithm; it only has to stay red.
        expect(
          HSVColor.fromColor(status.danger.solid).hue,
          anyOf(lessThan(15), greaterThan(345)),
        );
      }
    });

    test('accent swaps primary roles but keeps surfaces', () {
      final teal = buildColorScheme(brightness: Brightness.dark);
      final blue = buildColorScheme(
        brightness: Brightness.dark,
        accent: AppPalette.accents[1].color,
      );

      expect(blue.primary, isNot(teal.primary));
      expect(blue.primaryContainer, isNot(teal.primaryContainer));
      expect(blue.surface, teal.surface);
    });
  });

  test('AppTheme registers ExhaleColors for both modes', () {
    expect(AppTheme.light.extension<ExhaleColors>(), isNotNull);
    expect(AppTheme.dark.extension<ExhaleColors>(), isNotNull);
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.dark.brightness, Brightness.dark);
  });
}

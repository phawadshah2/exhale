import 'dart:math' as math;

import 'package:exhale/core/theme/app_color_scheme.dart';
import 'package:exhale/core/theme/app_palette.dart';
import 'package:exhale/core/theme/exhale_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double contrast(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
}

void main() {
  const normal = 4.5;

  for (final brightness in Brightness.values) {
    for (final swatch in AppPalette.accents) {
      final accent = brightness == Brightness.dark
          ? swatch.darkColor ?? swatch.color
          : swatch.color;
      final scheme = buildColorScheme(brightness: brightness, accent: accent);
      final exhale = ExhaleColors.fromScheme(scheme);
      final card = brightness == Brightness.dark
          ? scheme.surfaceContainerLow
          : scheme.surfaceContainerLowest;

      group('${brightness.name}, ${swatch.name}', () {
        void pair(String name, Color a, Color b, [double min = normal]) {
          test(name, () {
            expect(contrast(a, b), greaterThanOrEqualTo(min));
          });
        }

        pair(
          'onPrimaryContainer on primaryContainer',
          scheme.onPrimaryContainer,
          scheme.primaryContainer,
        );
        pair('onEmphasis on emphasis', exhale.onEmphasis, exhale.emphasis);
        pair('primary on the page', scheme.primary, scheme.surface);
        pair('primary on a card', scheme.primary, card);
        pair(
          'secondary text on the page',
          scheme.onSurfaceVariant,
          scheme.surface,
        );
        pair('secondary text on a card', scheme.onSurfaceVariant, card);
        pair(
          'secondary text on a panel',
          scheme.onSurfaceVariant,
          scheme.surfaceContainerHigh,
        );
        pair('success on a card', exhale.success.foreground, card);
        pair('warning on a card', exhale.warning.foreground, card);
        pair('danger on a card', exhale.danger.foreground, card);
      });
    }
  }
}

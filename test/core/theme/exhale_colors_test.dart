import 'package:exhale/core/theme/app_color_scheme.dart';
import 'package:exhale/core/theme/app_palette.dart';
import 'package:exhale/core/theme/app_theme.dart';
import 'package:exhale/core/theme/exhale_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExhaleColors emphasis', () {
    for (final brightness in Brightness.values) {
      for (final accent in [AppPalette.eucalyptus, AppPalette.ocean]) {
        test('$accent emphasis is that accent in ${brightness.name}', () {
          final scheme = buildColorScheme(
            brightness: brightness,
            accent: accent,
          );
          final colors = ExhaleColors.fromScheme(scheme);

          expect(colors.emphasis, scheme.primaryContainer);
          expect(colors.onEmphasis, scheme.onPrimaryContainer);
          expect(colors.emphasis, isNot(AppPalette.ink));
        });
      }
    }

    test('the ink accent is ink with white text in light', () {
      final colors = ExhaleColors.fromScheme(
        buildColorScheme(brightness: Brightness.light, accent: AppPalette.ink),
      );

      expect(colors.emphasis, AppPalette.ink);
      expect(colors.onEmphasis, Colors.white);
    });

    test('the ink accent is paper with ink text in dark', () {
      final colors = ExhaleColors.fromScheme(
        buildColorScheme(brightness: Brightness.dark, accent: AppPalette.ink),
      );

      expect(colors.emphasis, AppPalette.paper);
      expect(colors.onEmphasis, AppPalette.ink);
    });

    test('lerp blends emphasis', () {
      final light = ExhaleColors.fromScheme(
        buildColorScheme(brightness: Brightness.light),
      );
      final dark = ExhaleColors.fromScheme(
        buildColorScheme(brightness: Brightness.dark),
      );

      expect(light.lerp(dark, 1).emphasis, dark.emphasis);
      expect(light.lerp(dark, 1).onEmphasis, dark.onEmphasis);
      expect(light.lerp(dark, 0).emphasis, light.emphasis);
    });
  });

  group('ExhaleColors ringStart', () {
    test('a colour accent starts from the safe green', () {
      for (final brightness in Brightness.values) {
        final scheme = buildColorScheme(brightness: brightness);

        expect(
          ExhaleColors.fromScheme(scheme).ringStart,
          scheme.secondaryContainer,
        );
      }
    });

    test('the ink accent stays one colour, with no green in it', () {
      for (final brightness in Brightness.values) {
        final scheme = buildColorScheme(
          brightness: brightness,
          accent: AppPalette.ink,
        );

        expect(
          ExhaleColors.fromScheme(scheme).ringStart,
          scheme.primaryContainer,
        );
      }
    });

    test('lerp blends ringStart', () {
      final light = ExhaleColors.fromScheme(
        buildColorScheme(brightness: Brightness.light),
      );
      final ink = ExhaleColors.fromScheme(
        buildColorScheme(brightness: Brightness.light, accent: AppPalette.ink),
      );

      expect(light.lerp(ink, 1).ringStart, ink.ringStart);
    });
  });

  for (final (name, theme) in [
    ('light', AppTheme.light),
    ('dark', AppTheme.dark),
  ]) {
    testWidgets('filled buttons use emphasis in $name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: FilledButton(onPressed: () {}, child: const Text('Go')),
          ),
        ),
      );

      final style = Theme.of(tester.element(find.byType(FilledButton)))
          .filledButtonTheme
          .style!;
      final exhale = theme.extension<ExhaleColors>()!;

      expect(style.backgroundColor!.resolve({}), exhale.emphasis);
      expect(style.foregroundColor!.resolve({}), exhale.onEmphasis);
    });
  }
}

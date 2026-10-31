import 'package:exhale/core/theme/app_color_scheme.dart';
import 'package:exhale/core/theme/app_theme.dart';
import 'package:exhale/core/theme/exhale_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExhaleColors emphasis', () {
    test('light emphasis is ink with white text', () {
      final colors = ExhaleColors.fromScheme(
        buildColorScheme(brightness: Brightness.light),
      );

      expect(colors.emphasis, const Color(0xFF111418));
      expect(colors.onEmphasis, Colors.white);
    });

    test('dark emphasis is the accent', () {
      final scheme = buildColorScheme(brightness: Brightness.dark);
      final colors = ExhaleColors.fromScheme(scheme);

      expect(colors.emphasis, scheme.primaryContainer);
      expect(colors.onEmphasis, scheme.onPrimaryContainer);
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

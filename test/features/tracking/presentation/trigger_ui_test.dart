import 'dart:math' as math;

import 'package:exhale/core/theme/app_palette.dart';
import 'package:exhale/core/theme/app_theme.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:exhale/features/tracking/presentation/trigger_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<Map<Trigger, Color>> tints(
    WidgetTester tester,
    ThemeData theme,
  ) async {
    late Map<Trigger, Color> result;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Builder(
          builder: (context) {
            result = {for (final t in Trigger.values) t: t.tint(context)};
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return result;
  }

  testWidgets('every trigger has its own colour', (tester) async {
    final colors = await tints(tester, ThemeData.dark());

    expect(colors.values.toSet(), hasLength(Trigger.values.length));
  });

  for (final (name, theme, card) in [
    ('light', AppTheme.light, AppPalette.lightNeutrals.containerLowest),
    ('dark', AppTheme.dark, AppPalette.darkNeutrals.containerLow),
  ]) {
    testWidgets('a trigger chip is readable in $name', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Builder(
            builder: (c) {
              context = c;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      double contrast(Color a, Color b) {
        final l1 = a.computeLuminance();
        final l2 = b.computeLuminance();
        return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
      }

      for (final trigger in Trigger.values) {
        final chip = Color.alphaBlend(
          trigger.tint(context).withValues(alpha: 0.1),
          card,
        );
        expect(
          contrast(trigger.textTint(context), chip),
          greaterThanOrEqualTo(4.5),
          reason: trigger.name,
        );
      }
    });
  }

  testWidgets('a trigger keeps its hue in light and dark', (tester) async {
    final dark = await tints(tester, ThemeData.dark());
    final light = await tints(tester, ThemeData.light());

    for (final trigger in Trigger.values) {
      expect(
        HSLColor.fromColor(dark[trigger]!).hue,
        closeTo(HSLColor.fromColor(light[trigger]!).hue, 1),
        reason: trigger.name,
      );
    }
  });
}

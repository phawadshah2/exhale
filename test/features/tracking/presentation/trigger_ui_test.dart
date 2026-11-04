import 'dart:math' as math;

import 'package:exhale/core/theme/app_palette.dart';
import 'package:exhale/core/theme/app_theme.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
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

  testWidgets("a habit's triggers each have their own colour", (tester) async {
    final colors = await tints(tester, ThemeData.dark());

    for (final kind in HabitKind.values) {
      expect(
        {for (final trigger in kind.triggers) colors[trigger]},
        hasLength(kind.triggers.length),
        reason: kind.name,
      );
    }
  });

  testWidgets('no trigger looks like a status colour', (tester) async {
    final colors = await tints(tester, AppTheme.light);

    double apart(double a, double b) {
      final d = (a - b).abs() % 360;
      return math.min(d, 360 - d);
    }

    for (final MapEntry(key: trigger, value: color) in colors.entries) {
      final hue = HSLColor.fromColor(color).hue;
      for (final (status, statusHue) in [
        ('green', 160.0),
        ('amber', 38.0),
        ('red', 0.0),
      ]) {
        expect(
          apart(hue, statusHue),
          greaterThanOrEqualTo(35),
          reason: '${trigger.name} near $status',
        );
      }
    }
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
        expect(
          contrast(
            Theme.of(context).colorScheme.surface,
            trigger.textTint(context),
          ),
          greaterThanOrEqualTo(4.5),
          reason: 'selected ${trigger.name}',
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

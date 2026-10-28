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

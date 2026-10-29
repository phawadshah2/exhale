import 'package:exhale/core/theme/app_theme.dart';
import 'package:exhale/core/widgets/glow_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ShapeDecoration> _pumpGlow(WidgetTester tester, ThemeData theme) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: GlowButton(label: 'Go', onPressed: () {}),
      ),
    ),
  );
  final box = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byType(GlowButton),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  return box.decoration as ShapeDecoration;
}

void main() {
  testWidgets('the accent halo shows in dark mode', (tester) async {
    final decoration = await _pumpGlow(tester, AppTheme.dark);

    expect(decoration.shadows, isNotEmpty);
  });

  testWidgets('the ink button has no accent halo in light mode', (
    tester,
  ) async {
    final decoration = await _pumpGlow(tester, AppTheme.light);

    expect(decoration.shadows, isNull);
  });
}

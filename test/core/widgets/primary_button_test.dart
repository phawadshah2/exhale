import 'package:exhale/core/theme/app_palette.dart';
import 'package:exhale/core/theme/app_theme.dart';
import 'package:exhale/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/no_glow.dart';

void main() {
  for (final brightness in Brightness.values) {
    for (final swatch in AppPalette.accents) {
      testWidgets('${swatch.name} has no halo in ${brightness.name}', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.of(brightness, accent: swatch.color),
            home: Scaffold(
              body: PrimaryButton(label: 'Go', onPressed: () {}),
            ),
          ),
        );

        expect(shadowsUnder(tester, find.byType(PrimaryButton)), isEmpty);
      });
    }
  }
}

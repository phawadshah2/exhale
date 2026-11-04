import 'package:exhale/core/theme/app_palette.dart';
import 'package:exhale/core/theme/app_theme.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/tracking/domain/entities/limit_status.dart';
import 'package:exhale/features/tracking/presentation/limit_status_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('barColor is green, amber and red in ${brightness.name}', (
      tester,
    ) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.of(brightness, accent: AppPalette.ink),
          home: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(LimitStatus.under.barColor(context), context.exhale.success.solid);
      expect(LimitStatus.at.barColor(context), context.exhale.warning.solid);
      expect(LimitStatus.over.barColor(context), context.exhale.danger.solid);
      expect(
        LimitStatus.under.barColor(context),
        isNot(context.colors.primaryContainer),
      );
    });
  }
}

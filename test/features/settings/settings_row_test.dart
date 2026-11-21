import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/app_theme.dart';
import 'package:exhale/features/settings/presentation/widgets/settings_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a short value sits against the chevron at the trailing edge', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SettingsRow(
            icon: Icons.star,
            label: 'Edit plan',
            value: '5 today',
            onTap: () {},
          ),
        ),
      ),
    );

    final row = tester.getRect(find.byType(SettingsRow));
    final value = tester.getRect(find.text('5 today'));
    final chevron = tester.getRect(
      find.byWidgetPredicate(
        (w) => w is Icon && w.icon == AppIcons.chevronRight && w.size == 16,
      ),
    );
    expect(chevron.right, closeTo(row.right - AppSpacing.md, 0.5));
    expect(value.right, closeTo(chevron.left - AppSpacing.gutterSm, 0.5));
  });
}

import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/app_sheet.dart';
import 'package:exhale/features/settings/presentation/settings_copy.dart';
import 'package:exhale/features/settings/presentation/widgets/accent_picker.dart';
import 'package:exhale/features/settings/presentation/widgets/theme_preference_control.dart';
import 'package:flutter/material.dart';

/// Theme and accent in one sheet; both apply as they change.
Future<void> showAppearanceSheet(BuildContext context) => showAppSheet<void>(
  context,
  builder: (context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      0,
      AppSpacing.lg,
      AppSpacing.lg,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            SettingsCopy.appearance,
            style: context.textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _Label(SettingsCopy.theme),
        const SizedBox(height: AppSpacing.sm),
        const ThemePreferenceControl(),
        const SizedBox(height: AppSpacing.lg),
        const _Label(SettingsCopy.accent),
        const SizedBox(height: AppSpacing.sm),
        const AccentPicker(),
      ],
    ),
  ),
);

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: context.textTheme.labelSmall?.copyWith(
      color: context.colors.onSurfaceVariant,
    ),
  );
}

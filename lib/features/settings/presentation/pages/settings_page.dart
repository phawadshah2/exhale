import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/widgets/section_card.dart';
import 'package:exhale/features/settings/presentation/widgets/accent_picker.dart';
import 'package:exhale/features/settings/presentation/widgets/theme_preference_control.dart';
import 'package:exhale/features/settings/presentation/widgets/trigger_prompt_tile.dart';
import 'package:exhale/features/settings/presentation/widgets/your_day_sheet.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    return ListView(
      padding: AppSpacing.page.copyWith(
        top: insets.top + AppSpacing.sm,
        bottom: insets.bottom + AppSpacing.lg,
      ),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: AppSpacing.md),
        const SectionCard(
          title: 'Appearance',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.lg,
            children: [ThemePreferenceControl(), AccentPicker()],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const Card(clipBehavior: Clip.antiAlias, child: TriggerPromptTile()),
        const SizedBox(height: AppSpacing.md),
        const Card(clipBehavior: Clip.antiAlias, child: YourDayTile()),
        const SizedBox(height: AppSpacing.md),
        Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            leading: const Icon(AppIcons.palette),
            title: const Text('Design system'),
            trailing: const Icon(AppIcons.chevronRight),
            onTap: () => context.push(AppRoutes.designSystem),
          ),
        ),
      ],
    );
  }
}

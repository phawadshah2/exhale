import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/widgets/section_card.dart';
import 'package:exhale/features/settings/presentation/widgets/theme_preference_control.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: AppSpacing.page.copyWith(bottom: AppSpacing.xl),
        children: [
          const SectionCard(title: 'Theme', child: ThemePreferenceControl()),
          const SizedBox(height: AppSpacing.md),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: const Icon(Symbols.palette),
              title: const Text('Design system'),
              trailing: const Icon(Symbols.chevron_right),
              onTap: () => context.push(AppRoutes.designSystem),
            ),
          ),
        ],
      ),
    );
  }
}

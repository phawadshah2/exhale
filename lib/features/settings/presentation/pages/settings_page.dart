import 'package:exhale/app/shell/page_visits.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/widgets/scroll_reveal.dart';
import 'package:exhale/core/widgets/section_card.dart';
import 'package:exhale/core/widgets/status_bar_glass.dart';
import 'package:exhale/features/settings/presentation/widgets/accent_picker.dart';
import 'package:exhale/features/settings/presentation/widgets/theme_preference_control.dart';
import 'package:exhale/features/settings/presentation/widgets/trigger_prompt_tile.dart';
import 'package:exhale/features/settings/presentation/widgets/your_day_sheet.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    return ReplayOnVisit(
      tab: 1,
      child: StatusBarGlass(
        child: ListView(
          padding: AppSpacing.page.copyWith(
            top: insets.top + AppSpacing.sm,
            bottom: insets.bottom + AppSpacing.lg,
          ),
          children: [
            ScrollReveal(
              child: Text(
                'Settings',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const ScrollReveal(
              index: 1,
              child: SectionCard(
                title: 'Appearance',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.lg,
                  children: [ThemePreferenceControl(), AccentPicker()],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const ScrollReveal(
              index: 2,
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: TriggerPromptTile(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const ScrollReveal(
              index: 3,
              child: Card(clipBehavior: Clip.antiAlias, child: YourDayTile()),
            ),
          ],
        ),
      ),
    );
  }
}

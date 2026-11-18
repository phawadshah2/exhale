import 'package:exhale/app/shell/page_visits.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/scroll_reveal.dart';
import 'package:exhale/core/widgets/section_card.dart';
import 'package:exhale/core/widgets/status_bar_glass.dart';
import 'package:exhale/features/paywall/presentation/widgets/subscription_card.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/settings/presentation/widgets/accent_picker.dart';
import 'package:exhale/features/settings/presentation/widgets/theme_preference_control.dart';
import 'package:exhale/features/settings/presentation/widgets/trigger_prompt_tile.dart';
import 'package:exhale/features/settings/presentation/widgets/your_day_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
            const ScrollReveal(index: 2, child: SubscriptionCard()),
            const SizedBox(height: AppSpacing.md),
            const ScrollReveal(
              index: 3,
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: TriggerPromptTile(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const ScrollReveal(
              index: 4,
              child: Card(clipBehavior: Clip.antiAlias, child: YourDayTile()),
            ),
            const SizedBox(height: AppSpacing.md),
            const ScrollReveal(
              index: 5,
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: _LockScreenTile(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockScreenTile extends ConsumerWidget {
  const _LockScreenTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(currentSettingsProvider).showLiveActivity;
    return SwitchListTile.adaptive(
      value: enabled,
      onChanged: (value) => ref
          .read(settingsActionsProvider)
          .update((s) => s.copyWith(showLiveActivity: value)),
      secondary: Icon(AppIcons.clock, color: context.colors.primary),
      title: const Text('Show the countdown on the Lock Screen'),
      activeTrackColor: context.colors.primaryContainer,
    );
  }
}

import 'dart:async';

import 'package:exhale/app/shell/page_visits.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_palette.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/widgets/scroll_reveal.dart';
import 'package:exhale/core/widgets/status_bar_glass.dart';
import 'package:exhale/features/settings/domain/entities/theme_preference.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/settings/presentation/settings_copy.dart';
import 'package:exhale/features/settings/presentation/widgets/about_section.dart';
import 'package:exhale/features/settings/presentation/widgets/appearance_sheet.dart';
import 'package:exhale/features/settings/presentation/widgets/plan_section.dart';
import 'package:exhale/features/settings/presentation/widgets/settings_row.dart';
import 'package:exhale/features/settings/presentation/widgets/subscription_tile.dart';
import 'package:exhale/features/settings/presentation/widgets/your_day_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    const sections = <Widget>[
      _Tiles(),
      PlanShortcuts(),
      _YourDay(),
      _Logging(),
      _LockScreen(),
      _Appearance(),
      AboutSection(),
    ];
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
                SettingsCopy.title,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
            for (final (i, section) in sections.indexed) ...[
              SizedBox(height: i < 2 ? AppSpacing.md : AppSpacing.lg),
              ScrollReveal(index: i + 1, child: section),
            ],
            const SizedBox(height: AppSpacing.md),
            const VersionFooter(),
          ],
        ),
      ),
    );
  }
}

/// The plan and subscription tiles: side by side, stacked when large text
/// or a narrow screen leaves them too little room.
class _Tiles extends StatelessWidget {
  const _Tiles();

  @override
  Widget build(BuildContext context) {
    final stacked =
        MediaQuery.textScalerOf(context).scale(1) > 1.6 ||
        MediaQuery.sizeOf(context).width < 340;
    if (stacked) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [PlanTile(), SubscriptionTile()],
      );
    }
    return const IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          Expanded(child: PlanTile()),
          Expanded(child: SubscriptionTile()),
        ],
      ),
    );
  }
}

class _YourDay extends ConsumerWidget {
  const _YourDay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final window = ref.watch(currentSettingsProvider).dayWindow;
    return SettingsGroup(
      header: SettingsCopy.yourDay,
      rows: [
        SettingsRow(
          icon: AppIcons.morning,
          label: SettingsCopy.awake,
          value: window == null
              ? SettingsCopy.notSet
              : '${AppFormat.minuteOfDay(window.wakeMinute)} – '
                    '${AppFormat.minuteOfDay(window.bedMinute)}',
          onTap: () => unawaited(showYourDaySheet(context)),
        ),
      ],
    );
  }
}

class _Logging extends ConsumerWidget {
  const _Logging();

  @override
  Widget build(BuildContext context, WidgetRef ref) => SettingsGroup(
    header: SettingsCopy.logging,
    rows: [
      SettingsRow(
        icon: AppIcons.habit,
        label: SettingsCopy.askTrigger,
        switchValue: ref.watch(currentSettingsProvider).askForTrigger,
        onSwitch: (value) => unawaited(
          ref
              .read(settingsActionsProvider)
              .update(
                (s) => s.copyWith(
                  askForTrigger: value,
                  triggerPromptIntroSeen: true,
                ),
              ),
        ),
      ),
    ],
  );
}

class _LockScreen extends ConsumerWidget {
  const _LockScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) => SettingsGroup(
    header: SettingsCopy.lockScreen,
    rows: [
      SettingsRow(
        icon: AppIcons.lock,
        label: SettingsCopy.lockScreenCountdown,
        switchValue: ref.watch(currentSettingsProvider).showLiveActivity,
        onSwitch: (value) => unawaited(
          ref
              .read(settingsActionsProvider)
              .update((s) => s.copyWith(showLiveActivity: value)),
        ),
      ),
    ],
  );
}

class _Appearance extends ConsumerWidget {
  const _Appearance();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(currentSettingsProvider);
    void open() => unawaited(showAppearanceSheet(context));
    return SettingsGroup(
      header: SettingsCopy.appearance,
      rows: [
        SettingsRow(
          icon: AppIcons.appearance,
          label: SettingsCopy.theme,
          value: switch (settings.themePreference) {
            ThemePreference.light => SettingsCopy.themeLight,
            ThemePreference.dark => SettingsCopy.themeDark,
            ThemePreference.system => SettingsCopy.themeSystem,
          },
          onTap: open,
        ),
        SettingsRow(
          icon: AppIcons.palette,
          label: SettingsCopy.accent,
          value: AppPalette.accentAt(settings.accentIndex).name,
          onTap: open,
        ),
      ],
    );
  }
}

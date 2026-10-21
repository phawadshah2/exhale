import 'package:exhale/core/widgets/pill_segmented_control.dart';
import 'package:exhale/features/settings/domain/entities/theme_preference.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemePreferenceControl extends ConsumerWidget {
  const ThemePreferenceControl({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected =
        ref.watch(settingsProvider).value?.themePreference ??
        ThemePreference.system;

    return PillSegmentedControl<ThemePreference>(
      selected: selected,
      onChanged: (preference) => ref
          .read(settingsActionsProvider)
          .update((s) => s.copyWith(themePreference: preference)),
      segments: const [
        PillSegment(value: ThemePreference.light, label: 'Light'),
        PillSegment(value: ThemePreference.dark, label: 'Dark'),
        PillSegment(value: ThemePreference.system, label: 'System'),
      ],
    );
  }
}

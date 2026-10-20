import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TriggerPromptTile extends ConsumerWidget {
  const TriggerPromptTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(currentSettingsProvider).askForTrigger;
    return SwitchListTile.adaptive(
      value: enabled,
      onChanged: (value) => ref
          .read(settingsActionsProvider)
          .update(
            (s) =>
                s.copyWith(askForTrigger: value, triggerPromptIntroSeen: true),
          ),
      secondary: Icon(AppIcons.habit, color: context.colors.primary),
      title: const Text('Ask for a trigger'),
      subtitle: const Text('Pick what set it off before each log is saved'),
      activeTrackColor: context.colors.primaryContainer,
    );
  }
}

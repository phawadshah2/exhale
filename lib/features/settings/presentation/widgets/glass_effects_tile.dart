import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GlassEffectsTile extends ConsumerWidget {
  const GlassEffectsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(currentSettingsProvider).glassEffects;
    return SwitchListTile.adaptive(
      value: enabled,
      onChanged: (value) => ref
          .read(settingsActionsProvider)
          .update((s) => s.copyWith(glassEffects: value)),
      secondary: Icon(AppIcons.glass, color: context.colors.primary),
      title: const Text('Glass effects'),
      subtitle: const Text('Translucent tab bar, sheets and status bar'),
      activeTrackColor: context.colors.primaryContainer,
    );
  }
}

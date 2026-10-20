import 'dart:async';

import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/app_palette.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Accent swatches; the whole app re-tints from the chosen one.
class AccentPicker extends ConsumerWidget {
  const AccentPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      currentSettingsProvider.select((s) => s.accentIndex),
    );
    return Row(
      spacing: AppSpacing.md,
      children: [
        for (var i = 0; i < AppPalette.accents.length; i++)
          _Swatch(
            swatch: AppPalette.accents[i],
            selected: i == selected,
            onTap: () {
              unawaited(HapticFeedback.selectionClick());
              unawaited(
                ref
                    .read(settingsActionsProvider)
                    .update((s) => s.copyWith(accentIndex: i)),
              );
            },
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.swatch,
    required this.selected,
    required this.onTap,
  });

  final AccentSwatch swatch;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: '${swatch.name} accent',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          spacing: 6,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? swatch.color : Colors.transparent,
                  width: 2,
                ),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: swatch.color,
                ),
                child: selected
                    ? const Icon(AppIcons.check, size: 18, color: Colors.white)
                    : null,
              ),
            ),
            Text(
              swatch.name,
              style: context.textTheme.labelMedium?.copyWith(
                color: selected ? colors.onSurface : colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

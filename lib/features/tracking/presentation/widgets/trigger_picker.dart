import 'dart:async';

import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:exhale/features/tracking/presentation/trigger_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Two-column grid of the habit's trigger pills; tapping the selected one
/// clears it. A selected trigger from another habit is still shown.
class TriggerPicker extends ConsumerWidget {
  const TriggerPicker({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final Trigger? selected;
  final ValueChanged<Trigger?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitTriggers = ref.watch(habitProvider).kind.triggers;
    final current = selected;
    final triggers = [
      ...habitTriggers,
      if (current != null && !habitTriggers.contains(current)) current,
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - AppSpacing.gutterSm) / 2;
        return Wrap(
          spacing: AppSpacing.gutterSm,
          runSpacing: AppSpacing.gutterSm,
          children: [
            for (final trigger in triggers)
              SizedBox(
                width: width,
                child: _TriggerPill(
                  trigger: trigger,
                  isSelected: trigger == selected,
                  onTap: () {
                    unawaited(HapticFeedback.selectionClick());
                    onChanged(trigger == selected ? null : trigger);
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TriggerPill extends StatelessWidget {
  const _TriggerPill({
    required this.trigger,
    required this.isSelected,
    required this.onTap,
  });

  final Trigger trigger;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = isSelected
        ? colors.onPrimaryContainer
        : colors.onSurface;

    return Semantics(
      selected: isSelected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: ShapeDecoration(
              color: isSelected
                  ? colors.primaryContainer
                  : context.exhale.inset,
              shape: StadiumBorder(
                side: BorderSide(
                  color: isSelected
                      ? colors.primaryContainer
                      : colors.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
            ),
            child: Row(
              spacing: 10,
              children: [
                Icon(trigger.icon, size: 20, color: foreground),
                Expanded(
                  child: Text(
                    trigger.label,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: foreground,
                    ),
                  ),
                ),
                // if (isSelected)
                // Icon(AppIcons.check, size: 18, color: foreground),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/tracking/domain/entities/smoke_trigger.dart';
import 'package:exhale/features/tracking/presentation/smoke_trigger_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Two-column grid of trigger pills; tapping the selected one clears it.
class TriggerPicker extends StatelessWidget {
  const TriggerPicker({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final SmokeTrigger? selected;
  final ValueChanged<SmokeTrigger?> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - AppSpacing.gutterSm) / 2;
        return Wrap(
          spacing: AppSpacing.gutterSm,
          runSpacing: AppSpacing.gutterSm,
          children: [
            for (final trigger in SmokeTrigger.values)
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

  final SmokeTrigger trigger;
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
                  : colors.surfaceContainerHigh,
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
                if (isSelected)
                  Icon(AppIcons.check, size: 18, color: foreground),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/app_dialogs.dart';
import 'package:exhale/core/widgets/section_card.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/plan/presentation/widgets/projection_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One quick quit-date choice shown as a pill.
class QuitPresetOption {
  const QuitPresetOption({
    required this.label,
    required this.selected,
    required this.onSelect,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelect;
}

class QuitDateCard extends StatelessWidget {
  const QuitDateCard({
    required this.startDay,
    required this.quitDay,
    required this.plan,
    required this.isSteep,
    required this.earliest,
    required this.presets,
    required this.onPickDate,
    super.key,
  });

  final LogicalDay startDay;
  final LogicalDay quitDay;

  /// Null while the dates are invalid.
  final ReductionPlan? plan;
  final bool isSteep;
  final LogicalDay earliest;
  final List<QuitPresetOption> presets;
  final ValueChanged<LogicalDay> onPickDate;

  /// "in 23 days" / "in 8 weeks" / "in about 5 months" / "in about 2 years"
  static String relative(LogicalDay from, LogicalDay to) {
    final days = to.daysSince(from);
    if (days < 14) return 'in $days ${days == 1 ? 'day' : 'days'}';
    if (days <= 91) {
      return days % 7 == 0
          ? 'in ${days ~/ 7} weeks'
          : 'in about ${(days / 7).round()} weeks';
    }
    if (days < 730) return 'in about ${(days / 30.44).round()} months';
    return 'in about ${(days / 365.25).round()} years';
  }

  Future<void> _pick(BuildContext context) async {
    final picked = await showWheelPicker(
      context,
      title: 'Quit date',
      mode: CupertinoDatePickerMode.date,
      initial: quitDay.toLocalDate(),
      minimum: earliest.toLocalDate(),
    );
    if (picked != null) onPickDate(LogicalDay.fromDate(picked));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final preview = plan;

    return SectionCard(
      title: 'Quit date',
      subtitle: 'Your limit reaches 0 on this day',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: context.exhale.inset,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.inner,
              side: BorderSide(
                color: colors.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _pick(context),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  spacing: AppSpacing.md,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.surfaceContainerHighest,
                      ),
                      child: Icon(AppIcons.calendar, color: colors.primary),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppFormat.fullDate(quitDay),
                            style: text.headlineSmall?.copyWith(
                              color: colors.primary,
                            ),
                          ),
                          Text(
                            relative(startDay, quitDay),
                            style: text.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(AppIcons.chevronRight, color: colors.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.gutterSm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final preset in presets)
                _PresetPill(
                  label: preset.label,
                  selected: preset.selected,
                  onTap: () {
                    unawaited(HapticFeedback.selectionClick());
                    preset.onSelect();
                  },
                ),
            ],
          ),
          if (preview != null) ...[
            const SizedBox(height: AppSpacing.gutterSm),
            _Hint(
              icon: isSteep ? AppIcons.stress : AppIcons.info,
              color: isSteep
                  ? context.exhale.warning.foreground
                  : colors.primary,
              text: isSteep
                  ? "That's more than one fewer a day. A later date may "
                        'feel easier.'
                  : paceSentence(preview),
            ),
          ],
        ],
      ),
    );
  }
}

class _PresetPill extends StatelessWidget {
  const _PresetPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: ShapeDecoration(
            color: selected ? colors.primaryContainer : context.exhale.inset,
            shape: const StadiumBorder(),
          ),
          child: Text(
            label,
            style: context.textTheme.labelLarge?.copyWith(
              color: selected ? colors.onPrimaryContainer : colors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.sm,
      children: [
        Icon(icon, size: 18, color: color),
        Expanded(child: Text(text, style: context.textTheme.bodySmall)),
      ],
    );
  }
}

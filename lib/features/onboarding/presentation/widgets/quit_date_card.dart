import 'dart:async';

import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/app_dialogs.dart';
import 'package:exhale/core/widgets/section_card.dart';
import 'package:exhale/features/onboarding/presentation/providers/setup_form_provider.dart';
import 'package:exhale/features/onboarding/presentation/widgets/projection_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuitDateCard extends StatelessWidget {
  const QuitDateCard({
    required this.form,
    required this.earliest,
    required this.latest,
    required this.onPickDate,
    required this.onSelectPreset,
    super.key,
  });

  final SetupFormState form;
  final LogicalDay earliest;
  final LogicalDay latest;
  final ValueChanged<LogicalDay> onPickDate;
  final ValueChanged<QuitPreset> onSelectPreset;

  /// "in 23 days" / "in 8 weeks" / "in about 9 weeks"
  static String relative(LogicalDay from, LogicalDay to) {
    final days = to.daysSince(from);
    if (days < 14) return 'in $days ${days == 1 ? 'day' : 'days'}';
    if (days % 7 == 0) return 'in ${days ~/ 7} weeks';
    return 'in about ${(days / 7).round()} weeks';
  }

  Future<void> _pick(BuildContext context) async {
    final picked = await showWheelPicker(
      context,
      title: 'Quit date',
      mode: CupertinoDatePickerMode.date,
      initial: form.quitDay.toLocalDate(),
      minimum: earliest.toLocalDate(),
      maximum: latest.toLocalDate(),
    );
    if (picked != null) onPickDate(LogicalDay.fromDate(picked));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final preview = form.preview;

    return SectionCard(
      title: 'Quit date',
      subtitle: 'Your limit reaches 0 on this day',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: colors.surfaceContainer,
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
                    Icon(AppIcons.calendar, color: colors.primary),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppFormat.fullDate(form.quitDay),
                            style: text.headlineSmall?.copyWith(
                              color: colors.primary,
                            ),
                          ),
                          Text(
                            relative(form.startDay, form.quitDay),
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
              for (final preset in QuitPreset.values)
                _PresetPill(
                  label: preset.label,
                  selected: form.quitPreset == preset,
                  onTap: () {
                    unawaited(HapticFeedback.selectionClick());
                    onSelectPreset(preset);
                  },
                ),
            ],
          ),
          if (preview != null) ...[
            const SizedBox(height: AppSpacing.gutterSm),
            _Hint(
              icon: form.isSteep ? AppIcons.stress : AppIcons.info,
              color: form.isSteep
                  ? context.exhale.warning.foreground
                  : colors.primary,
              text: form.isSteep
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
            color: selected
                ? colors.primaryContainer
                : colors.surfaceContainerHigh,
            shape: StadiumBorder(
              side: BorderSide(
                color: selected
                    ? colors.primaryContainer
                    : colors.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
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

import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/presentation/habit_icon.dart';
import 'package:exhale/features/tracking/domain/entities/habit_log.dart';
import 'package:exhale/features/tracking/presentation/trigger_ui.dart';
import 'package:flutter/material.dart';

/// One log: trigger tile, time, note and trigger chip. Tap to edit. Among
/// several habits, [habit] and [when] replace the trigger tile, the time and
/// the note.
class LogRow extends StatelessWidget {
  const LogRow({
    required this.log,
    required this.onTap,
    this.habit,
    this.when,
    super.key,
  });

  final HabitLog log;
  final VoidCallback onTap;
  final Habit? habit;
  final String? when;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final trigger = log.trigger;
    final note = log.note;
    final tint = trigger?.tint(context) ?? colors.onSurfaceVariant;
    final habit = this.habit;

    return InkWell(
      onTap: onTap,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.gutterSm),
        child: Row(
          spacing: AppSpacing.gutterSm,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                habit?.kind.icon ?? trigger?.icon ?? AppIcons.clock,
                size: 20,
                color: habit == null ? tint : colors.primary,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    habit?.name ?? AppFormat.time(log.loggedAt),
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    when ?? note ?? 'No note',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (trigger == null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: ShapeDecoration(
                  shape: StadiumBorder(
                    side: BorderSide(color: colors.outlineVariant),
                  ),
                ),
                child: Text(
                  'No trigger',
                  style: text.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: ShapeDecoration(
                  color: tint.withValues(alpha: 0.1),
                  shape: StadiumBorder(
                    side: BorderSide(color: tint.withValues(alpha: 0.35)),
                  ),
                ),
                child: Text(
                  trigger.label,
                  style: text.labelMedium?.copyWith(
                    color: tint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/presentation/habit_icon.dart';
import 'package:exhale/features/habit/presentation/habit_wording.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:flutter/material.dart';

/// "Vaping · Drops to 10 in 4d" with a "STAGE 2 / 9" chip; outside the stages,
/// the plan's start or quit date.
class StagePill extends StatelessWidget {
  const StagePill({
    required this.plan,
    required this.today,
    required this.habit,
    super.key,
  });

  final ReductionPlan plan;
  final Habit habit;
  final LogicalDay today;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = context.textTheme.titleSmall;
    final stage = plan.stageOn(today);
    final quit = stage == null && plan.hasStartedOn(today);
    final success = context.exhale.success.foreground;
    final tint = quit ? success : colors.primaryContainer;
    final foreground = quit ? success : colors.primary;

    final String chip;
    final Widget label;
    if (stage != null) {
      chip = 'STAGE ${stage.number} / ${plan.stageCount}';
      label = _NameAndTarget(
        name: habit.name,
        target: today == plan.startDay
            ? 'Day 1, plan starts today'
            : habit.nextTarget(plan, today),
        style: style,
      );
    } else {
      chip = quit ? 'QUIT' : 'SOON';
      final large = context.hasLargeText;
      label = Text(
        quit
            ? '${habit.freeTitle} since ${AppFormat.monthDay(plan.quitDay)}'
            : 'Plan starts ${AppFormat.monthDay(plan.startDay)} · '
                  'Daily limit: ${plan.startLimit}',
        style: style,
        maxLines: large ? null : 1,
        overflow: large ? null : TextOverflow.ellipsis,
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: ShapeDecoration(
        color: colors.surfaceContainerHigh,
        shape: StadiumBorder(
          side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),
      child: Row(
        spacing: 10,
        children: [
          Icon(habit.kind.icon, size: 20, color: foreground),
          Expanded(child: label),
          // Capped so large text leaves the label room.
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: ShapeDecoration(
                color: tint.withValues(alpha: 0.12),
                shape: StadiumBorder(
                  side: BorderSide(color: tint.withValues(alpha: 0.4)),
                ),
              ),
              child: Text(
                chip,
                style: context.textTheme.labelMedium?.copyWith(
                  color: foreground,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The name gives way first, so a long one never hides the target. With large
/// text both wrap instead.
class _NameAndTarget extends StatelessWidget {
  const _NameAndTarget({
    required this.name,
    required this.target,
    required this.style,
  });

  final String name;
  final String target;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => context.hasLargeText
      ? Text('$name · $target', style: style)
      : LayoutBuilder(
          builder: (context, box) => Row(
            children: [
              Flexible(
                child: Text(
                  name,
                  style: style,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: box.maxWidth),
                child: Text(
                  ' · $target',
                  style: style,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
}

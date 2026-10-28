import 'dart:async';
import 'dart:math' as math;

import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/presentation/habit_wording.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// The plan as a vertical stepper: the stage just done, the current one,
/// the next one and the quit date.
class PlanCard extends StatelessWidget {
  const PlanCard({
    required this.habitId,
    required this.plan,
    required this.today,
    required this.habit,
    super.key,
  });

  final int habitId;
  final ReductionPlan plan;
  final LogicalDay today;
  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final stage = plan.stageOn(today);
    final previous = stage == null || stage.number == 1
        ? null
        : plan.stages[stage.number - 2];
    final next = stage == null
        ? (plan.hasStartedOn(today) ? null : plan.stages.first)
        : plan.stages.where((s) => s.number == stage.number + 1).firstOrNull;
    final later = next == null ? 0 : plan.stageCount - next.number;
    final daysToGo = plan.quitDay.daysSince(today);
    final percent = (plan.progressOn(today) * 100).floor();
    final quitDate = AppFormat.monthDay(plan.quitDay);

    final steps = <_Step>[
      if (previous != null)
        _Step(
          marker: _Marker.done,
          title: 'Stage ${previous.number} · ${previous.limit} a day',
          detail:
              '${AppFormat.dayRange(previous.startDay, previous.endDay)} '
              '· done',
        ),
      if (stage != null)
        _Step(
          marker: _Marker.current,
          number: stage.number,
          title: 'Stage ${stage.number} · ${stage.limit} a day · now',
          detail:
              'Since ${AppFormat.shortWeekdayDate(stage.startDay)} · day '
              '${stage.dayNumberOf(today)} of ${stage.lengthDays}',
          progress: stage.dayNumberOf(today) / stage.lengthDays,
        ),
      if (next != null)
        _Step(
          marker: _Marker.next,
          number: next.number,
          title: 'Stage ${next.number} · ${next.limit} a day',
          detail:
              'Starts ${AppFormat.shortWeekdayDate(next.startDay)}'
              '${later > 0 ? ' · then $later more' : ''}',
          // Stages between the next one and the quit date.
          dashedAfter: later > 0,
        ),
      _Step(
        marker: _Marker.finish,
        title: '${habit.freeTitle} from $quitDate',
        detail: daysToGo > 0
            ? '$daysToGo ${daysToGo == 1 ? 'day' : 'days'} to go'
            : 'You reached your quit date',
      ),
    ];

    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.md,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text('Your plan', style: text.titleMedium),
                      Text(
                        stage == null
                            ? '$percent% of the way'
                            : 'Stage ${stage.number} of ${plan.stageCount} '
                                  '· $percent% of the way',
                        style: text.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _EditPill(
                  onTap: () {
                    unawaited(HapticFeedback.selectionClick());
                    unawaited(context.push(AppRoutes.editPlanFor(habitId)));
                  },
                ),
              ],
            ),
            Column(
              children: [
                for (var i = 0; i < steps.length; i++)
                  _StepRow(
                    step: steps[i],
                    connector: i == steps.length - 1
                        ? _Connector.none
                        : steps[i].marker == _Marker.done
                        ? _Connector.done
                        : steps[i].dashedAfter
                        ? _Connector.dashed
                        : _Connector.plain,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditPill extends StatelessWidget {
  const _EditPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: 'Edit plan',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          child: Center(
            widthFactor: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: ShapeDecoration(
                shape: StadiumBorder(
                  side: BorderSide(
                    color: colors.primary.withValues(alpha: 0.4),
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 5,
                children: [
                  Icon(AppIcons.edit, size: 14, color: colors.primary),
                  Text(
                    'Edit',
                    style: context.textTheme.labelMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _Marker { done, current, next, finish }

enum _Connector { none, done, plain, dashed }

class _Step {
  const _Step({
    required this.marker,
    required this.title,
    required this.detail,
    this.number,
    this.progress,
    this.dashedAfter = false,
  });

  final _Marker marker;
  final String title;
  final String detail;
  final int? number;

  /// How far through the current stage today is, 0 to 1.
  final double? progress;
  final bool dashedAfter;
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.connector});

  static const double _marker = 26;

  final _Step step;
  final _Connector connector;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final current = step.marker == _Marker.current;
    final progress = step.progress;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.gutterSm,
        children: [
          SizedBox(
            width: _marker,
            child: Column(
              children: [
                _MarkerDot(step: step),
                if (connector != _Connector.none)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: CustomPaint(
                        size: const Size(2, double.infinity),
                        painter: _ConnectorPainter(
                          color: connector == _Connector.done
                              ? colors.primaryContainer
                              : colors.outlineVariant,
                          dashed: connector == _Connector.dashed,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: 2,
                bottom: connector == _Connector.none ? 0 : AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    step.title,
                    style: text.titleSmall?.copyWith(
                      color: current ? colors.primary : null,
                      fontWeight: current ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  Text(
                    step.detail,
                    style: text.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  if (progress != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: ClipRRect(
                        borderRadius: AppRadius.pill,
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: colors.surfaceContainerHighest,
                          color: colors.primaryContainer,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkerDot extends StatelessWidget {
  const _MarkerDot({required this.step});

  final _Step step;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final number = Text(
      '${step.number}',
      style: context.textTheme.labelSmall?.copyWith(
        color: step.marker == _Marker.current
            ? colors.primary
            : colors.onSurface,
        fontWeight: FontWeight.w700,
      ),
    );
    return Container(
      width: _StepRow._marker,
      height: _StepRow._marker,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: step.marker == _Marker.done ? colors.primaryContainer : null,
        border: switch (step.marker) {
          _Marker.done => null,
          _Marker.current => Border.all(
            color: colors.primaryContainer,
            width: 2,
          ),
          _ => Border.all(color: colors.outlineVariant, width: 1.5),
        },
      ),
      child: switch (step.marker) {
        _Marker.done => Icon(
          AppIcons.check,
          size: 14,
          color: colors.onPrimaryContainer,
        ),
        _Marker.finish => Icon(
          AppIcons.flag,
          size: 13,
          color: context.exhale.warning.foreground,
        ),
        _ => number,
      },
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  const _ConnectorPainter({required this.color, required this.dashed});

  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final x = size.width / 2;
    if (!dashed) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      return;
    }
    for (var y = 0.0; y < size.height; y += 6) {
      canvas.drawLine(
        Offset(x, y),
        Offset(x, math.min(y + 3, size.height)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ConnectorPainter old) =>
      old.color != color || old.dashed != dashed;
}

import 'dart:math' as math;

import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/plan/presentation/widgets/edit_card.dart';
import 'package:exhale/features/plan/presentation/widgets/stage_ring.dart';
import 'package:flutter/material.dart';

/// one fewer every 7 days
String dropSentence(ReductionPlan plan) {
  if (plan.startLimit > plan.totalDays) return 'dropping fast';
  final days = plan.daysPerDrop;
  if (days < 1.5) return 'dropping about every day';
  final rounded = days.round();
  return days == rounded
      ? 'one fewer every $rounded days'
      : 'one fewer about every $rounded days';
}

/// Each stage's limit, then 0. Past 10 rings, null stands for the gap.
List<int?> previewLimits(ReductionPlan plan) {
  final limits = [for (final stage in plan.stages) stage.limit, 0];
  if (limits.length <= 10) return limits;
  return [...limits.take(5), null, ...limits.skip(limits.length - 4)];
}

/// The stages a plan makes, before it is saved.
class PlanPreviewCard extends StatelessWidget {
  const PlanPreviewCard({required this.plan, super.key});

  final ReductionPlan plan;

  @override
  Widget build(BuildContext context) {
    final count = plan.stageCount;
    return EditCard(
      title: 'What that makes',
      side: Text(
        '$count ${count == 1 ? 'stage' : 'stages'} · ${dropSentence(plan)}',
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
      children: [_PreviewRings(limits: previewLimits(plan))],
    );
  }
}

class _PreviewRings extends StatelessWidget {
  const _PreviewRings({required this.limits});

  final List<int?> limits;

  static const double _maxSize = 30;
  static const double _strokePerPoint = 4 / 44;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final success = context.exhale.success.foreground;
    // The header above already says this in words.
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = math.min(_maxSize, constraints.maxWidth / limits.length);
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final (index, limit) in limits.indexed)
                _ring(
                  context,
                  limit: limit,
                  size: size,
                  ring: limit == 0
                      ? success
                      : index == 0
                      ? colors.primaryContainer
                      : colors.outlineVariant,
                  dashed: index != 0 && limit != 0,
                  number: limit == 0 ? success : colors.onSurface,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _ring(
    BuildContext context, {
    required int? limit,
    required double size,
    required Color ring,
    required bool dashed,
    required Color number,
  }) {
    final label = Center(
      child: MediaQuery.withNoTextScaling(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            limit?.toString() ?? '…',
            style: context.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: number,
            ),
          ),
        ),
      ),
    );
    return SizedBox.square(
      dimension: size,
      child: limit == null
          ? label
          : CustomPaint(
              painter: StageRingPainter(
                fill: 0,
                strokeWidth: size * _strokePerPoint,
                color: ring,
                track: ring,
                dashed: dashed,
              ),
              child: label,
            ),
    );
  }
}

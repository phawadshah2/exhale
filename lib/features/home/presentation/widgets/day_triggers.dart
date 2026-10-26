import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:exhale/features/tracking/domain/entities/trigger_breakdown.dart';
import 'package:exhale/features/tracking/domain/services/progress_calculator.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:exhale/features/tracking/presentation/trigger_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The three most used triggers on [day], each with its count and share.
/// Rows open [onSelect] with their trigger when it is set.
class DayTriggers extends ConsumerWidget {
  const DayTriggers({
    required this.habitId,
    required this.day,
    this.onSelect,
    super.key,
  });

  final int habitId;
  final LogicalDay day;
  final ValueChanged<Trigger>? onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(logsForDayProvider((habitId: habitId, day: day)));
    final firstDay = ref.watch(planHistoryProvider(habitId)).value?.firstDay;
    final loaded = logs.value;
    if (loaded == null) return const SizedBox.shrink();

    final top = ProgressCalculator.triggerBreakdown(loaded).top(3);
    final isToday = day == ref.watch(todayProvider);
    if (top.isEmpty) {
      return loaded.isEmpty && day == firstDay
          ? const _Placeholder()
          : const SizedBox.shrink();
    }

    final colors = context.colors;
    final rankColors = [
      context.exhale.danger.foreground,
      colors.primary,
      context.exhale.warning.foreground,
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 9,
        children: [
          Text(
            "${isToday ? "TODAY'S" : "THAT DAY'S"} TRIGGERS"
            '${onSelect == null ? '' : ' · TAP TO SEE LOGS'}',
            style: context.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
            ),
          ),
          for (var i = 0; i < top.length; i++)
            _TriggerRow(share: top[i], color: rankColors[i], onTap: onSelect),
        ],
      ),
    );
  }
}

class _TriggerRow extends StatelessWidget {
  const _TriggerRow({
    required this.share,
    required this.color,
    required this.onTap,
  });

  final TriggerShare share;
  final Color color;
  final ValueChanged<Trigger>? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final percent = (share.fraction * 100).round();
    return InkWell(
      onTap: onTap == null ? null : () => onTap!(share.trigger),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 28),
        child: Row(
          spacing: 10,
          children: [
            SizedBox(
              width: 78,
              child: Text(
                share.trigger.label,
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: share.fraction,
                  minHeight: 8,
                  color: color,
                  backgroundColor: colors.outlineVariant,
                ),
              ),
            ),
            SizedBox(
              width: 56,
              child: Text(
                '${share.count} · $percent%',
                textAlign: TextAlign.right,
                style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ),
            Icon(
              AppIcons.chevronRight,
              size: 14,
              color: colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return CustomPaint(
      painter: _DashedBorderPainter(color: colors.outlineVariant),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        child: Text(
          "Today's triggers show here once you log.",
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.75),
          const Radius.circular(18),
        ),
      );
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}

import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/app_motion.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/smooth_switcher.dart';
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
  Widget build(BuildContext context, WidgetRef ref) => AnimatedSize(
    duration: const Duration(milliseconds: 500),
    curve: Curves.easeInOutCubic,
    alignment: Alignment.topCenter,
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      layoutBuilder: smoothSwitcherLayout,
      child: _content(context, ref),
    ),
  );

  Widget _content(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(logsForDayProvider((habitId: habitId, day: day)));
    final firstDay = ref.watch(planHistoryProvider(habitId)).value?.firstDay;
    final loaded = logs.value;
    if (loaded == null) return const SizedBox.shrink(key: ValueKey('none'));

    final top = ProgressCalculator.triggerBreakdown(loaded).top(3);
    final isToday = day == ref.watch(todayProvider);
    if (top.isEmpty) {
      return loaded.isEmpty && day == firstDay
          ? const _Placeholder(key: ValueKey('placeholder'))
          : const SizedBox.shrink(key: ValueKey('none'));
    }

    final colors = context.colors;
    return Container(
      key: ValueKey('panel-$day'),
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
          for (final share in top)
            _TriggerRow(
              key: ValueKey('$day-${share.trigger.name}'),
              share: share,
              color: share.trigger.tint(context),
              onTap: onSelect,
            ),
        ],
      ),
    );
  }
}

class _TriggerRow extends StatelessWidget {
  const _TriggerRow({
    required super.key,
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
                // Keyed by day, so each day's bars fill from empty.
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: share.fraction),
                  duration: AppMotion.fill,
                  curve: AppMotion.fillCurve,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    color: color,
                    backgroundColor: colors.outlineVariant,
                  ),
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
  const _Placeholder({super.key});

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

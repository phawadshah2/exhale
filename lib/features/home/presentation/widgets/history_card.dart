import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/pill_segmented_control.dart';
import 'package:exhale/features/home/presentation/providers/home_providers.dart';
import 'package:exhale/features/home/presentation/widgets/history_chart.dart';
import 'package:exhale/features/tracking/domain/entities/period_range.dart';
import 'package:exhale/features/tracking/domain/entities/period_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HistoryCard extends ConsumerWidget {
  const HistoryCard({required this.onDayTap, super.key});

  final ValueChanged<LogicalDay> onDayTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(chartPeriodProvider);
    final summary = ref.watch(periodSummaryProvider).value;
    final text = context.textTheme;
    final colors = context.colors;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Smoking History', style: text.headlineSmall),
                      Text(
                        'Paced tapering progress',
                        style: text.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 148,
                  child: PillSegmentedControl<ChartPeriod>(
                    selected: period,
                    onChanged: ref.read(chartPeriodProvider.notifier).select,
                    segments: const [
                      PillSegment(value: ChartPeriod.week, label: 'Week'),
                      PillSegment(value: ChartPeriod.month, label: 'Month'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
              decoration: BoxDecoration(
                color: colors.surfaceContainer.withValues(alpha: 0.6),
                borderRadius: AppRadius.inner,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: summary == null
                    ? const SizedBox(
                        height: HistoryChart.chartHeight + 26,
                        child: Center(
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      )
                    : HistoryChart(
                        key: ValueKey(summary.range),
                        summary: summary,
                        onDayTap: onDayTap,
                      ),
              ),
            ),
            if (summary != null) ...[
              const SizedBox(height: AppSpacing.gutterSm),
              _Legend(summary: summary),
            ],
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.summary});

  final PeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme.labelMedium;
    final colors = context.colors;
    final average = summary.averagePerDay;
    if (average == null) {
      return Text(
        'Nothing tracked in this period yet.',
        style: text?.copyWith(color: colors.onSurfaceVariant),
      );
    }

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                shape: BoxShape.circle,
              ),
            ),
            Text('Avg ${average.toStringAsFixed(1)}/day', style: text),
          ],
        ),
        Text(
          '${summary.daysOver} ${summary.daysOver == 1 ? 'day' : 'days'} over',
          style: text?.copyWith(
            color: summary.daysOver > 0
                ? context.exhale.danger.foreground
                : colors.onSurfaceVariant,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            Icon(
              AppIcons.checkCircle,
              size: 16,
              color: context.exhale.success.foreground,
            ),
            Text(
              '${summary.daysWithin} '
              '${summary.daysWithin == 1 ? 'day' : 'days'} within limit',
              style: text?.copyWith(color: context.exhale.success.foreground),
            ),
          ],
        ),
      ],
    );
  }
}

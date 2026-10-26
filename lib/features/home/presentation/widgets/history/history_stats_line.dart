import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/tracking/domain/entities/period_stats.dart';
import 'package:flutter/material.dart';

/// "Avg 7.7/day · 0 days over · 3 days on track" for any period.
class HistoryStatsLine extends StatelessWidget {
  const HistoryStatsLine({required this.stats, super.key});

  final PeriodStats stats;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme.labelMedium;
    final colors = context.colors;
    final average = stats.avgPerDay;
    if (average == null) {
      return Text(
        'Nothing tracked in this period yet.',
        style: text?.copyWith(color: colors.onSurfaceVariant),
      );
    }

    String days(int n) => '$n ${n == 1 ? 'day' : 'days'}';
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 16,
      runSpacing: 4,
      children: [
        Text('Avg ${average.toStringAsFixed(1)}/day', style: text),
        Text(
          '${days(stats.daysOver)} over',
          style: text?.copyWith(
            color: stats.daysOver > 0
                ? context.exhale.danger.foreground
                : colors.onSurfaceVariant,
          ),
        ),
        Text(
          '${days(stats.daysOnTrack)} on track',
          style: text?.copyWith(color: context.exhale.success.foreground),
        ),
      ],
    );
  }
}

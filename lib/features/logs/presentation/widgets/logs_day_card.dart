import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/status_badge.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/logs/presentation/providers/logs_providers.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:exhale/features/tracking/presentation/limit_status_ui.dart';
import 'package:flutter/material.dart';

/// The Logs summary when a single day is open: that day's count against its
/// limit, or one trigger's share of it.
class LogsDayCard extends StatelessWidget {
  const LogsDayCard({
    required this.entry,
    required this.today,
    required this.habit,
    required this.trigger,
    super.key,
  });

  final LogsDay entry;
  final LogicalDay today;
  final Habit habit;
  final Trigger? trigger;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final word = entry.day == today ? 'today' : 'that day';
    final progress = entry.progress;
    final trigger = this.trigger;
    final matching = trigger == null
        ? 0
        : entry.logs.where((log) => log.trigger == trigger).length;
    final balance = progress == null
        ? ''
        : progress.overBy > 0
        ? '${progress.overBy} over'
        : '${progress.remaining} left';
    final percent = entry.count == 0
        ? 0
        : (100 * matching / entry.count).round();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.gutterSm,
          children: [
            Text(
              AppFormat.relativeDate(entry.day, today: today),
              style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (trigger != null)
              Text(
                '$matching of ${entry.count} logs $word · $percent%',
                key: const Key('logs-day-summary'),
                style: text.titleMedium,
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${entry.count} logged',
                      key: const Key('logs-day-summary'),
                      style: text.titleMedium,
                    ),
                  ),
                  if (progress != null)
                    StatusBadge(
                      label: progress.badgeLabel(habit),
                      colors: progress.status.colors(context),
                    )
                  else
                    Text(
                      'Before your plan',
                      style: text.labelLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            if (progress != null) ...[
              if (trigger != null) ...[
                Text(
                  'Allowed $word: ${entry.count} of ${progress.limit} used · '
                  '$balance',
                  style: text.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                _SplitBar(
                  trigger: matching,
                  other: entry.count - matching,
                  left: progress.remaining,
                ),
              ] else
                Text(
                  '${progress.limit} allowed $word',
                  style: text.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SplitBar extends StatelessWidget {
  const _SplitBar({
    required this.trigger,
    required this.other,
    required this.left,
  });

  final int trigger;
  final int other;
  final int left;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClipRRect(
      borderRadius: AppRadius.pill,
      child: SizedBox(
        height: 8,
        child: Row(
          children: [
            for (final (count, color) in [
              (trigger, colors.primaryContainer),
              (other, colors.onSurfaceVariant.withValues(alpha: 0.5)),
              (left, colors.surfaceContainerHighest),
            ])
              if (count > 0)
                Expanded(
                  flex: count,
                  child: ColoredBox(color: color),
                ),
          ],
        ),
      ),
    );
  }
}

import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/logs/presentation/logs_query.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:exhale/features/tracking/presentation/trigger_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The first few logs of today; the rest are behind "See all logs".
class TodayLogsCard extends ConsumerWidget {
  const TodayLogsCard({required this.habitId, super.key});

  static const _shown = 3;

  final int habitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = context.textTheme;
    final today = ref.watch(todayProvider);
    final logs =
        ref.watch(logsForDayProvider((habitId: habitId, day: today))).value ??
        const [];
    final more = logs.length - _shown;

    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Today's logs", style: text.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            if (logs.isEmpty)
              Text(
                'Nothing logged today.',
                style: text.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            for (final log in logs.take(_shown))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppFormat.time(log.loggedAt),
                        style: text.titleSmall,
                      ),
                    ),
                    if (log.trigger case final trigger?)
                      Text(
                        trigger.label,
                        style: text.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            if (more > 0) ...[
              const SizedBox(height: AppSpacing.xs),
              TextButton(
                onPressed: () => openLogs(
                  context,
                  LogsQuery(habitId: habitId, from: today, to: today),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 44),
                ),
                child: Text(
                  '+$more more today · See all logs',
                  style: text.labelLarge?.copyWith(color: colors.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

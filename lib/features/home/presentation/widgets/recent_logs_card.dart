import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/home/presentation/providers/home_providers.dart';
import 'package:exhale/features/home/presentation/widgets/logs_card_header.dart';
import 'package:exhale/features/logs/presentation/logs_query.dart';
import 'package:exhale/features/logs/presentation/widgets/log_row.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:exhale/features/tracking/presentation/widgets/log_editor_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The latest logs across every habit, newest first. Tap one to edit it;
/// "See all logs" opens Logs for all habits.
class RecentLogsCard extends ConsumerWidget {
  const RecentLogsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final today = ref.watch(todayProvider);
    final boundary = ref.watch(dayBoundaryProvider);
    final logs = ref.watch(recentLogsProvider).value ?? const [];

    final divider = Divider(
      height: 1,
      color: colors.outlineVariant.withValues(alpha: 0.5),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LogsCardHeader(
          title: 'Recent logs',
          onSeeAll: () => openLogs(context, const LogsQuery()),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(
              children: [
                if (logs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      'Nothing logged yet.',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                for (var i = 0; i < logs.length; i++) ...[
                  if (i > 0) divider,
                  Builder(
                    builder: (context) {
                      final log = logs[i];
                      final day = boundary.dayOf(log.loggedAt);
                      return LogRow(
                        log: log,
                        habit: ref.watch(habitProvider(log.habitId))?.habit,
                        when: AppFormat.dayAndTime(
                          log.loggedAt,
                          day: day,
                          today: today,
                        ),
                        onTap: () => showLogEditorSheet(
                          context,
                          habitId: log.habitId,
                          day: day,
                          log: log,
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

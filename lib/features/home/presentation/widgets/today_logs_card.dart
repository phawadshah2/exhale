import 'dart:async';

import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/app_motion.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/smooth_switcher.dart';
import 'package:exhale/features/home/presentation/widgets/logs_card_header.dart';
import 'package:exhale/features/logs/presentation/logs_query.dart';
import 'package:exhale/features/logs/presentation/widgets/log_row.dart';
import 'package:exhale/features/tracking/domain/entities/habit_log.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:exhale/features/tracking/presentation/widgets/log_editor_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The newest few logs of today; the rest expand in place. "See all logs"
/// opens Logs.
class TodayLogsCard extends ConsumerStatefulWidget {
  const TodayLogsCard({required this.habitId, super.key});

  final int habitId;

  @override
  ConsumerState<TodayLogsCard> createState() => _TodayLogsCardState();
}

class _TodayLogsCardState extends ConsumerState<TodayLogsCard> {
  static const _shown = 3;

  bool _expanded = false;

  int get habitId => widget.habitId;

  void _toggle() {
    unawaited(HapticFeedback.selectionClick());
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final today = ref.watch(todayProvider);
    final logs =
        ref.watch(logsForDayProvider((habitId: habitId, day: today))).value ??
        const [];
    final more = logs.length - _shown;

    void seeAll() =>
        openLogs(context, LogsQuery(habitId: habitId, from: today, to: today));

    final divider = Divider(
      height: 1,
      color: colors.outlineVariant.withValues(alpha: 0.5),
    );
    final newest = logs.reversed.toList();
    final shown = newest.take(_shown).toList();
    final extra = newest.skip(_shown).toList();

    Widget row(HabitLog log) => LogRow(
      log: log,
      onTap: () =>
          showLogEditorSheet(context, habitId: habitId, day: today, log: log),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LogsCardHeader(title: "Today's logs", onSeeAll: seeAll),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(
              children: [
                if (shown.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      'Nothing logged today.',
                      style: text.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                for (var i = 0; i < shown.length; i++) ...[
                  if (i > 0) divider,
                  row(shown[i]),
                ],
                SmoothSwitcher(
                  resize: true,
                  child: _expanded && extra.isNotEmpty
                      ? Column(
                          key: const ValueKey('more'),
                          children: [
                            for (final log in extra) ...[divider, row(log)],
                          ],
                        )
                      : const SizedBox(
                          key: ValueKey('less'),
                          width: double.infinity,
                        ),
                ),
                if (more > 0) ...[
                  divider,
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _toggle,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 6,
                        children: [
                          Text(
                            _expanded ? 'Show less' : '+$more more today',
                            style: text.labelLarge?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          AnimatedRotation(
                            turns: _expanded ? 0.5 : 0,
                            duration: AppMotion.swap,
                            curve: AppMotion.swapCurve,
                            child: Icon(
                              AppIcons.chevronDown,
                              size: 14,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
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

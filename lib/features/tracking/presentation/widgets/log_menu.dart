import 'dart:async';

import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/liquid_glass.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:exhale/features/habit/presentation/habit_icon.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/tracking/domain/entities/daily_progress.dart';
import 'package:exhale/features/tracking/domain/entities/limit_status.dart';
import 'package:exhale/features/tracking/presentation/limit_status_ui.dart';
import 'package:exhale/features/tracking/presentation/log_flow.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:exhale/features/tracking/presentation/widgets/log_editor_sheet.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The + button's menu. One habit: Log now, then Add a missed log and Add a
/// habit. Several: a row per habit with today's count, then the same two.
Future<void> showLogMenu(
  BuildContext context,
  WidgetRef ref, {
  required Rect anchor,
}) async {
  final habits = ref.read(activeHabitsProvider).value;
  if (habits == null || habits.isEmpty) return;
  final today = ref.read(todayProvider);
  final single = habits.length == 1;

  final progress = single
      ? const <int, DailyProgress?>{}
      : {
          for (final habit in habits)
            habit.id: await _todayProgress(ref, habit.id, today),
        };
  if (!context.mounted) return;

  final missedLogHabit = single ? habits.single : habits.first;
  await showGlassMenu(
    context,
    anchor: anchor,
    items: [
      if (single)
        GlassMenuItem(
          label: 'Log now',
          icon: AppIcons.add,
          onSelected: () => logNow(context, ref, habitId: habits.single.id),
        )
      else
        for (final habit in habits)
          _habitItem(context, ref, habit, progress[habit.id]),
      GlassMenuItem(
        label: 'Add a missed log',
        icon: AppIcons.clock,
        onSelected: () =>
            showLogEditorSheet(context, habitId: missedLogHabit.id, day: today),
      ),
      GlassMenuItem(
        label: 'Add a habit',
        icon: AppIcons.addCircle,
        onSelected: () => unawaited(context.push<void>(AppRoutes.addHabit)),
      ),
    ],
  );
}

GlassMenuItem _habitItem(
  BuildContext context,
  WidgetRef ref,
  TrackedHabit habit,
  DailyProgress? progress,
) {
  final colors = context.colors;
  return GlassMenuItem(
    label: habit.habit.name,
    icon: habit.habit.kind.icon,
    detail: progress == null
        ? null
        : '${progress.count} of ${progress.limit} today',
    detailColor: progress == null || progress.status == LimitStatus.under
        ? colors.onSurfaceVariant
        : progress.status.barColor(context),
    onSelected: () => logNow(context, ref, habitId: habit.id),
  );
}

/// Read from the repositories, not the stream providers: a provider with no
/// listener is paused and its `.future` can hang.
Future<DailyProgress?> _todayProgress(
  WidgetRef ref,
  int habitId,
  LogicalDay today,
) async {
  final history = await ref
      .read(planRepositoryProvider)
      .watchHistory(habitId)
      .first;
  if (history == null) return null;
  final boundary = ref.read(dayBoundaryProvider);
  final logs = await ref
      .read(habitLogRepositoryProvider)
      .watchLogs(
        habitId: habitId,
        from: boundary.startOf(today),
        to: boundary.endOf(today),
      )
      .first;
  return DailyProgress(
    day: today,
    count: logs.length,
    limit: history.limitOn(today),
  );
}

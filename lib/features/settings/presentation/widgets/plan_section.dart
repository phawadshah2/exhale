import 'dart:async';

import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:exhale/features/habit/presentation/habit_icon.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:exhale/features/settings/domain/plan_tile_summary.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/settings/presentation/widgets/settings_row.dart';
import 'package:exhale/features/settings/presentation/widgets/settings_tile.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The plan tile; it opens plan details. Empty until the plan loads.
class PlanTile extends ConsumerWidget {
  const PlanTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habit = ref.watch(singleHabitProvider);
    final history = habit == null
        ? null
        : ref.watch(planHistoryProvider(habit.id)).value;
    if (habit == null || history == null) return const SizedBox.shrink();
    return SettingsTile(
      icon: habit.habit.kind.icon,
      accentIcon: true,
      summary: planTileSummary(
        habit: habit,
        history: history,
        today: ref.watch(todayProvider),
      ),
      onTap: () => unawaited(context.push(AppRoutes.planDetailsFor(habit.id))),
    );
  }
}

/// Edit plan, Price and Change habit: links to the pages that already exist.
class PlanShortcuts extends ConsumerWidget {
  const PlanShortcuts({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habit = ref.watch(singleHabitProvider);
    if (habit == null) return const SizedBox.shrink();
    final history = ref.watch(planHistoryProvider(habit.id)).value;
    final today = ref.watch(todayProvider);
    final symbol = ref.watch(currentSettingsProvider).currencySymbol;
    return SettingsGroup(
      rows: [
        SettingsRow(
          icon: AppIcons.trendDown,
          label: 'Edit plan',
          value: history == null ? null : '${history.limitOn(today)} today',
          onTap: () => unawaited(context.push(AppRoutes.editPlanFor(habit.id))),
        ),
        if (habit.habit.tracksCost)
          SettingsRow(
            icon: AppIcons.savings,
            label: 'Price',
            value: _price(habit, symbol),
            onTap: () => unawaited(
              context.push(AppRoutes.editPlanFor(habit.id, focusPrice: true)),
            ),
          ),
        SettingsRow(
          icon: habit.habit.kind.icon,
          label: 'Change habit',
          onTap: () =>
              unawaited(context.push(AppRoutes.changeHabitFor(habit.id))),
        ),
      ],
    );
  }

  /// "$12 a pod", or "Not set".
  static String _price(TrackedHabit habit, String symbol) {
    final cents = habit.priceCents;
    if (cents == null) return 'Not set';
    final money = AppFormat.money(
      cents,
      symbol: symbol,
      wholeUnits: cents % 100 == 0,
    );
    return '$money a ${habit.habit.container ?? habit.habit.unit}';
  }
}

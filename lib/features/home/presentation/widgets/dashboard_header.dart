import 'dart:async';

import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/widgets/circle_icon_button.dart';
import 'package:exhale/features/home/presentation/widgets/habit_switcher.dart';
import 'package:exhale/features/home/presentation/widgets/home_header.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum DashboardHeaderKind { greeting, back }

/// The top of a habit dashboard: the greeting on Home, a back bar on Details.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    required this.habitId,
    required this.kind,
    required this.today,
    required this.now,
    required this.name,
    required this.dayNumber,
    super.key,
  });

  final int habitId;
  final DashboardHeaderKind kind;
  final LogicalDay today;
  final DateTime now;
  final String? name;
  final int? dayNumber;

  @override
  Widget build(BuildContext context) {
    void editPlan() => unawaited(context.push(AppRoutes.editPlanFor(habitId)));

    return switch (kind) {
      DashboardHeaderKind.greeting => Row(
        children: [
          Expanded(
            child: HomeHeader(
              today: today,
              now: now,
              name: name,
              dayNumber: dayNumber,
            ),
          ),
          IconButton(
            tooltip: 'Edit plan',
            onPressed: editPlan,
            icon: const Icon(AppIcons.tune),
          ),
        ],
      ),
      DashboardHeaderKind.back => Row(
        spacing: AppSpacing.sm,
        children: [
          CircleIconButton(
            tooltip: 'Back',
            icon: AppIcons.back,
            onPressed: context.pop,
          ),
          Expanded(
            child: Center(child: HabitSwitcher(habitId: habitId)),
          ),
          CircleIconButton(
            tooltip: 'Edit plan',
            icon: AppIcons.tune,
            onPressed: editPlan,
          ),
        ],
      ),
    };
  }
}

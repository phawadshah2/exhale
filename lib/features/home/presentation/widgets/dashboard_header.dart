import 'dart:async';

import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/home/presentation/widgets/home_header.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum DashboardHeaderKind { greeting, back }

/// The top of a habit dashboard: the greeting on Home, a back bar on Details.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    required this.habitId,
    required this.kind,
    required this.habitName,
    required this.today,
    required this.now,
    required this.name,
    required this.dayNumber,
    super.key,
  });

  final int habitId;
  final DashboardHeaderKind kind;
  final String habitName;
  final LogicalDay today;
  final DateTime now;
  final String? name;
  final int? dayNumber;

  @override
  Widget build(BuildContext context) {
    final tune = IconButton(
      tooltip: 'Edit plan',
      onPressed: () => unawaited(context.push(AppRoutes.editPlanFor(habitId))),
      icon: const Icon(AppIcons.tune),
    );
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
          tune,
        ],
      ),
      DashboardHeaderKind.back => Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: context.pop,
            icon: const Icon(AppIcons.back),
          ),
          Expanded(
            child: Text(
              habitName,
              style: context.textTheme.titleLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          tune,
        ],
      ),
    };
  }
}

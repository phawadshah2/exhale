import 'package:exhale/features/habit/presentation/widgets/tracked_habit_guard.dart';
import 'package:exhale/features/home/presentation/widgets/habit_dashboard.dart';
import 'package:flutter/material.dart';

class HabitDetailsPage extends StatelessWidget {
  const HabitDetailsPage({required this.habitId, super.key});

  final int habitId;

  @override
  Widget build(BuildContext context) => TrackedHabitGuard(
    habitId: habitId,
    child: Scaffold(
      // Keyed so switching habit starts at the top, with fresh card state.
      body: HabitDashboard(
        key: ValueKey(habitId),
        habitId: habitId,
        header: DashboardHeaderKind.back,
      ),
    ),
  );
}

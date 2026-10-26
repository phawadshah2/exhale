import 'package:exhale/features/home/presentation/widgets/habit_dashboard.dart';
import 'package:flutter/material.dart';

class HabitDetailsPage extends StatelessWidget {
  const HabitDetailsPage({required this.habitId, super.key});

  final int habitId;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: HabitDashboard(habitId: habitId, header: DashboardHeaderKind.back),
  );
}

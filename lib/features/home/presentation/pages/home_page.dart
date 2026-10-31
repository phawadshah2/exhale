import 'package:exhale/app/shell/page_visits.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/home/presentation/widgets/habit_dashboard.dart';
import 'package:exhale/features/home/presentation/widgets/habit_list_home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(primaryHabitProvider) == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    final habitId = ref.watch(singleHabitIdProvider);
    return ReplayOnVisit(
      tab: 0,
      child: habitId == null
          ? const HabitListHome()
          : HabitDashboard(
              habitId: habitId,
              header: DashboardHeaderKind.greeting,
            ),
    );
  }
}

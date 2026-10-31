import 'package:exhale/core/presentation/providers/clock_providers.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/home/presentation/providers/home_providers.dart';
import 'package:exhale/features/home/presentation/widgets/dashboard_header.dart';
import 'package:exhale/features/home/presentation/widgets/dashboard_skeleton.dart';
import 'package:exhale/features/home/presentation/widgets/history_card.dart';
import 'package:exhale/features/home/presentation/widgets/pace_line.dart';
import 'package:exhale/features/home/presentation/widgets/plan_card.dart';
import 'package:exhale/features/home/presentation/widgets/quote_card.dart';
import 'package:exhale/features/home/presentation/widgets/ring_card.dart';
import 'package:exhale/features/home/presentation/widgets/scroll_reveal.dart';
import 'package:exhale/features/home/presentation/widgets/stage_pill.dart';
import 'package:exhale/features/home/presentation/widgets/stats_grid.dart';
import 'package:exhale/features/home/presentation/widgets/today_logs_card.dart';
import 'package:exhale/features/home/presentation/widgets/why_card.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:exhale/features/home/presentation/widgets/dashboard_header.dart'
    show DashboardHeaderKind;

/// One habit's dashboard: ring, impact, history, plan, why and today's logs.
class HabitDashboard extends ConsumerWidget {
  const HabitDashboard({
    required this.habitId,
    required this.header,
    super.key,
  });

  final int habitId;
  final DashboardHeaderKind header;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider).now();
    final settings = ref.watch(currentSettingsProvider);
    final tracked = ref.watch(habitProvider(habitId));
    if (tracked == null) {
      return const DashboardSkeleton();
    }
    final habit = tracked.habit;
    final reason = tracked.reason;
    final history = ref.watch(planHistoryProvider(habitId)).value;
    final stats = ref.watch(habitStatsProvider(habitId)).value;

    // Edge to edge: content scrolls under the status bar and the floating
    // tab bar (reported as bottom padding). Every card is built once, not
    // lazily: a card rebuilt after scrolling off would start at another
    // height and make the page jump at the bottom.
    final insets = MediaQuery.paddingOf(context);
    return SingleChildScrollView(
      padding: AppSpacing.page.copyWith(
        top: insets.top + AppSpacing.sm,
        bottom: insets.bottom + AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScrollReveal(
            child: DashboardHeader(
              habitId: habitId,
              kind: header,
              habitName: habit.name,
              today: today,
              now: now,
              name: settings.userName,
              dayNumber: stats?.dayNumber,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (history != null)
            ScrollReveal(
              index: 1,
              child: StagePill(
                plan: history.current,
                today: today,
                habit: habit,
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          ScrollReveal(index: 2, child: RingCard(habitId: habitId)),
          ScrollReveal(index: 2, child: PaceLine(habitId: habitId)),
          if (stats != null) ...[
            const SizedBox(height: AppSpacing.md),
            ScrollReveal(
              child: StatsGrid(
                habitId: habitId,
                stats: stats,
                currencySymbol: settings.currencySymbol,
                habit: habit,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          ScrollReveal(child: HistoryCard(habitId: habitId)),
          if (history != null) ...[
            const SizedBox(height: AppSpacing.md),
            ScrollReveal(
              child: PlanCard(
                habitId: habitId,
                plan: history.current,
                today: today,
                habit: habit,
              ),
            ),
          ],
          if (reason != null) ...[
            const SizedBox(height: AppSpacing.md),
            ScrollReveal(child: WhyCard(reason: reason)),
          ],
          const SizedBox(height: AppSpacing.md),
          ScrollReveal(child: TodayLogsCard(habitId: habitId)),
          if (stats != null) ...[
            const SizedBox(height: AppSpacing.md),
            ScrollReveal(child: QuoteCard(dayNumber: stats.dayNumber)),
          ],
        ],
      ),
    );
  }
}

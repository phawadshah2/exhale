import 'package:exhale/core/presentation/providers/clock_providers.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/features/home/presentation/providers/home_providers.dart';
import 'package:exhale/features/home/presentation/widgets/day_card.dart';
import 'package:exhale/features/home/presentation/widgets/history_card.dart';
import 'package:exhale/features/home/presentation/widgets/home_header.dart';
import 'package:exhale/features/home/presentation/widgets/quote_card.dart';
import 'package:exhale/features/home/presentation/widgets/stage_pill.dart';
import 'package:exhale/features/home/presentation/widgets/stats_grid.dart';
import 'package:exhale/features/home/presentation/widgets/why_card.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider).now();
    final settings = ref.watch(currentSettingsProvider);
    final history = ref.watch(planHistoryProvider).value;
    final stats = ref.watch(homeStatsProvider).value;
    final habit = settings.habit;
    final reason = settings.reason;

    // Edge to edge: content scrolls under the status bar and the floating
    // tab bar (reported as bottom padding).
    final insets = MediaQuery.paddingOf(context);
    return ListView(
      padding: AppSpacing.page.copyWith(
        top: insets.top + AppSpacing.sm,
        bottom: insets.bottom + AppSpacing.lg,
      ),
      children: [
        HomeHeader(
          today: today,
          now: now,
          name: settings.userName,
          dayNumber: stats?.dayNumber,
        ),
        const SizedBox(height: AppSpacing.md),
        if (history != null)
          StagePill(plan: history.current, today: today, habit: habit),
        const SizedBox(height: AppSpacing.md),
        const DayCard(),
        if (reason != null) ...[
          const SizedBox(height: AppSpacing.md),
          WhyCard(reason: reason),
        ],
        const SizedBox(height: AppSpacing.md),
        const HistoryCard(),
        if (stats != null) ...[
          const SizedBox(height: AppSpacing.md),
          StatsGrid(
            stats: stats,
            currencySymbol: settings.currencySymbol,
            habit: habit,
          ),
          const SizedBox(height: AppSpacing.md),
          QuoteCard(dayNumber: stats.dayNumber),
        ],
      ],
    );
  }
}

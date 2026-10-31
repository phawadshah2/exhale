import 'package:exhale/core/presentation/providers/clock_providers.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/home/presentation/providers/home_providers.dart';
import 'package:exhale/features/home/presentation/widgets/combined_impact_card.dart';
import 'package:exhale/features/home/presentation/widgets/habit_summary_card.dart';
import 'package:exhale/features/home/presentation/widgets/home_header.dart';
import 'package:exhale/features/home/presentation/widgets/quote_card.dart';
import 'package:exhale/features/home/presentation/widgets/recent_logs_card.dart';
import 'package:exhale/features/home/presentation/widgets/scroll_reveal.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Home with two or more habits: a card per habit, their combined impact and
/// the latest logs across them.
class HabitListHome extends ConsumerWidget {
  const HabitListHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = context.textTheme;
    final today = ref.watch(todayProvider);
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider).now();
    final settings = ref.watch(currentSettingsProvider);
    final habits = ref.watch(activeHabitsProvider).value ?? const [];
    final impact = ref.watch(combinedImpactProvider).value;
    // Habits come oldest first, so this counts from the longest-running plan.
    final dayNumber = impact?.habits.firstOrNull?.stats.dayNumber;

    // Built once, not lazily, for the same reason as the dashboard.
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
            child: HomeHeader(
              today: today,
              now: now,
              name: settings.userName,
              dayNumber: dayNumber,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ScrollReveal(
            index: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text("Today's habits", style: text.titleLarge),
                  ),
                  Text(
                    '${habits.length} active',
                    style: text.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (final (i, habit) in habits.indexed) ...[
            const SizedBox(height: AppSpacing.md),
            ScrollReveal(
              key: ValueKey(habit.id),
              index: i + 2,
              child: HabitSummaryCard(habitId: habit.id),
            ),
          ],
          if (impact != null) ...[
            const SizedBox(height: AppSpacing.md),
            ScrollReveal(
              child: CombinedImpactCard(
                impact: impact,
                currencySymbol: settings.currencySymbol,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          const ScrollReveal(child: RecentLogsCard()),
          if (dayNumber != null) ...[
            const SizedBox(height: AppSpacing.md),
            ScrollReveal(child: QuoteCard(dayNumber: dayNumber)),
          ],
        ],
      ),
    );
  }
}

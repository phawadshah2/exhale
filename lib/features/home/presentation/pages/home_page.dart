import 'dart:async';

import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/failure_message.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/presentation/providers/clock_providers.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/widgets/app_snack_bar.dart';
import 'package:exhale/core/widgets/glow_button.dart';
import 'package:exhale/core/widgets/scroll_edge_blur.dart';
import 'package:exhale/features/home/presentation/providers/home_providers.dart';
import 'package:exhale/features/home/presentation/widgets/history_card.dart';
import 'package:exhale/features/home/presentation/widgets/home_header.dart';
import 'package:exhale/features/home/presentation/widgets/quote_card.dart';
import 'package:exhale/features/home/presentation/widgets/stage_pill.dart';
import 'package:exhale/features/home/presentation/widgets/stats_grid.dart';
import 'package:exhale/features/home/presentation/widgets/today_card.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/tracking/domain/entities/smoke_log.dart';
import 'package:exhale/features/tracking/domain/entities/smoke_trigger.dart';
import 'package:exhale/features/tracking/domain/usecases/log_smoke.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:exhale/features/tracking/presentation/widgets/day_detail_sheet.dart';
import 'package:exhale/features/tracking/presentation/widgets/trigger_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  /// Asks for a trigger first (unless turned off), then saves the log.
  /// Dismissing the trigger sheet cancels the log.
  Future<void> _logSmoke(BuildContext context, WidgetRef ref) async {
    unawaited(HapticFeedback.mediumImpact());
    final loggedAt = ref.read(clockProvider).now();
    final settings = ref.read(currentSettingsProvider);

    SmokeTrigger? trigger;
    if (settings.askForTrigger) {
      final firstPrompt = !settings.triggerPromptIntroSeen;
      final answer = await showTriggerSheet(
        context,
        offerToStopAsking: firstPrompt,
      );
      if (answer == null || !context.mounted) return;
      trigger = answer.trigger;
      if (firstPrompt) {
        await ref
            .read(settingsActionsProvider)
            .update(
              (s) => s.copyWith(
                triggerPromptIntroSeen: true,
                askForTrigger: answer.keepAsking,
              ),
            );
        if (!context.mounted) return;
      }
    }

    final result = await ref.read(logSmokeProvider)(
      LogSmokeInput(loggedAt: loggedAt, trigger: trigger),
    );
    if (!context.mounted) return;
    switch (result) {
      case Success(value: final SmokeLog log):
        showAppSnackBar(
          context,
          message: 'Logged at ${AppFormat.time(log.loggedAt)}',
          actionLabel: 'Undo',
          onAction: () => ref.read(deleteSmokeLogProvider)(log.id),
          duration: const Duration(seconds: 2),
        );
      case FailureResult(:final failure):
        showAppSnackBar(
          context,
          message: failureMessage(failure),
          tone: SnackTone.danger,
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider).now();
    final settings = ref.watch(currentSettingsProvider);
    final history = ref.watch(planHistoryProvider).value;
    final progress = ref.watch(todayProgressProvider).value;
    final latestLog = ref.watch(latestLogProvider).value;
    final stats = ref.watch(homeStatsProvider).value;

    // Edge to edge: content scrolls under the status bar (blurred by
    // ScrollEdgeBlur) and the floating tab bar (reported as bottom padding).
    final insets = MediaQuery.paddingOf(context);
    return ScrollEdgeBlur(
      child: ListView(
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
          if (history != null) StagePill(plan: history.current, today: today),
          const SizedBox(height: AppSpacing.md),
          if (progress == null || history == null)
            const SizedBox(
              height: 360,
              child: Center(child: CircularProgressIndicator.adaptive()),
            )
          else
            TodayCard(
              progress: progress,
              plan: history.planOn(today),
              today: today,
              now: now,
              latestLog: latestLog,
              isFirstDay: today == history.firstDay,
            ),
          const SizedBox(height: AppSpacing.md),
          GlowButton(
            label: 'Log a smoke',
            icon: AppIcons.flame,
            onPressed: progress == null ? null : () => _logSmoke(context, ref),
          ),
          const SizedBox(height: AppSpacing.lg),
          HistoryCard(onDayTap: (day) => showDayDetailSheet(context, day)),
          if (stats != null) ...[
            const SizedBox(height: AppSpacing.md),
            StatsGrid(stats: stats, currencySymbol: settings.currencySymbol),
            const SizedBox(height: AppSpacing.md),
            QuoteCard(dayNumber: stats.dayNumber),
          ],
        ],
      ),
    );
  }
}

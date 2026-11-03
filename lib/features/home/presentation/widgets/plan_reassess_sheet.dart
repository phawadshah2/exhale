import 'dart:math' as math;

import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/app_sheet.dart';
import 'package:exhale/features/habit/presentation/habit_wording.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/home/presentation/providers/stage_card_provider.dart';
import 'package:exhale/features/home/presentation/widgets/stage_choice_sheet.dart';
import 'package:exhale/features/plan/domain/services/plan_choices.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:exhale/features/plan/presentation/providers/plan_report_provider.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the reassess sheet (Stages spec 5.4). The choices and their dates
/// are worked out now and stay as they are while the sheet is open.
Future<void> showPlanReassessSheet(
  BuildContext context,
  WidgetRef ref, {
  required int habitId,
  required ReassessCardData card,
}) async {
  final history = ref.read(planHistoryProvider(habitId)).value;
  if (history == null) return;
  final today = ref.read(todayProvider);
  final choices = PlanChoices.reassess(
    current: history.current,
    today: today,
    average: card.average,
  );
  await showAppDraggableSheet<void>(
    context,
    initialSize: 0.9,
    builder: (context, controller) => StageChoiceSheet(
      controller: controller,
      habitId: habitId,
      card: card,
      today: today,
      choices: choices,
      title: 'Back around where you started',
      lead:
          'About ${card.average} a day these last two weeks. It happens, '
          'and none of this gets wiped.',
      header: [_StillYours(habitId: habitId)],
      footer: [_SupportLines(habitId: habitId)],
    ),
  );
}

/// Avoided, saved and days kept across every plan, as on Plan details.
class _StillYours extends ConsumerWidget {
  const _StillYours({required this.habitId});

  final int habitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(planReportProvider(habitId)).value?.totals;
    final habit = ref.watch(habitProvider(habitId))?.habit;
    if (totals == null || habit == null) return const SizedBox.shrink();
    final symbol = ref.watch(currentSettingsProvider).currencySymbol;
    final saved = totals.savedCents;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.sm,
      children: [
        Text('Still yours', style: context.textTheme.titleSmall),
        StageFigures(
          figures: [
            StageFigure(
              value: AppFormat.count(totals.avoided),
              label: 'avoided',
            ),
            if (habit.tracksCost && saved != null)
              StageFigure(
                value: AppFormat.money(math.max(0, saved), symbol: symbol),
                label: 'saved',
              ),
            StageFigure(
              value: AppFormat.count(totals.kept),
              label: 'days kept',
            ),
          ],
        ),
      ],
    );
  }
}

class _SupportLines extends ConsumerWidget {
  const _SupportLines({required this.habitId});

  final int habitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habit = ref.watch(habitProvider(habitId))?.habit;
    if (habit == null) return const SizedBox.shrink();
    final text = context.textTheme;
    final stopSuddenly = habit.stopSuddenlyLine;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.sm,
      children: [
        Text(
          habit.supportLine,
          style: text.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        if (stopSuddenly != null)
          Text(
            stopSuddenly,
            style: text.bodySmall?.copyWith(
              color: context.colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

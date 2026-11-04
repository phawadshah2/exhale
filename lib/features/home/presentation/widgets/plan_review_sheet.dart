import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/app_sheet.dart';
import 'package:exhale/features/home/presentation/providers/stage_card_provider.dart';
import 'package:exhale/features/home/presentation/widgets/stage_choice_sheet.dart';
import 'package:exhale/features/plan/domain/services/plan_choices.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:exhale/features/tracking/presentation/trigger_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the review sheet (Stages spec 5.3). The choices and their dates are
/// worked out now and stay as they are while the sheet is open.
Future<void> showPlanReviewSheet(
  BuildContext context,
  WidgetRef ref, {
  required int habitId,
  required ReviewCardData card,
}) async {
  final history = ref.read(planHistoryProvider(habitId)).value;
  final stats = ref.read(
    stageWindowStatsProvider((
      habitId: habitId,
      earlierEnd: card.earlierWindowEndDay,
      windowEnd: card.windowEndDay,
    )),
  );
  if (history == null || stats == null) return;
  final today = ref.read(todayProvider);
  final choices = PlanChoices.review(
    current: history.current,
    today: today,
    windowAverage: stats.average,
    checkedLimit: history.limitOn(card.windowEndDay),
  );
  await showAppSheet<void>(
    context,
    builder: (context) => StageChoiceSheet(
      habitId: habitId,
      card: card,
      today: today,
      choices: choices,
      title: "Let's look at the plan",
      lead: 'Not a telling-off. Just the numbers.',
      header: [
        StageFigures(
          figures: [
            StageFigure(value: '${stats.logged}', label: 'logged'),
            StageFigure(value: '${stats.allowed}', label: 'allowed'),
            StageFigure(value: 'About ${stats.average}', label: 'a day'),
          ],
        ),
        if (stats.topTriggers.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text('What came up most', style: context.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final share in stats.topTriggers)
                _TriggerPill('${share.trigger.label} · ${share.count}'),
            ],
          ),
        ],
      ],
    ),
  );
}

class _TriggerPill extends StatelessWidget {
  const _TriggerPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 32),
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutterSm),
    decoration: BoxDecoration(
      color: context.exhale.inset,
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    child: Text(label, style: context.textTheme.labelLarge),
  );
}

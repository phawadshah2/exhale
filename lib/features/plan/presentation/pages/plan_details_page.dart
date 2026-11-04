import 'dart:async';
import 'dart:math' as math;

import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_motion.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/circle_icon_button.dart';
import 'package:exhale/core/widgets/load_failure.dart';
import 'package:exhale/core/widgets/scroll_reveal.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/presentation/habit_wording.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/logs/presentation/logs_query.dart';
import 'package:exhale/features/plan/domain/services/plan_report.dart';
import 'package:exhale/features/plan/presentation/plan_copy.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:exhale/features/plan/presentation/providers/plan_report_provider.dart';
import 'package:exhale/features/plan/presentation/widgets/current_stage_card.dart';
import 'package:exhale/features/plan/presentation/widgets/edit_pill.dart';
import 'package:exhale/features/plan/presentation/widgets/plan_totals_card.dart';
import 'package:exhale/features/plan/presentation/widgets/stage_row.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Every stage of the plan so far and to come, with the whole plan's totals.
class PlanDetailsPage extends ConsumerWidget {
  const PlanDetailsPage({required this.habitId, super.key});

  final int habitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracked = ref.watch(habitProvider(habitId));
    final report = ref.watch(planReportProvider(habitId));
    final failed =
        report.failedToLoad || ref.watch(activeHabitsProvider).failedToLoad;
    final loaded = report.value;
    if (failed || tracked == null || loaded == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: AppSpacing.page.copyWith(top: AppSpacing.sm),
                child: const _BackButton(),
              ),
              Expanded(
                child: failed
                    ? LoadFailure(
                        message: PlanCopy.loadFailure,
                        onRetry: () => ref
                          ..invalidate(activeHabitsProvider)
                          ..invalidate(planHistoryProvider(habitId))
                          ..invalidate(priceHistoryProvider(habitId))
                          ..invalidate(logsInRangeProvider),
                      )
                    : const Center(child: CircularProgressIndicator.adaptive()),
              ),
            ],
          ),
        ),
      );
    }
    return _PlanDetails(habitId: habitId, report: loaded, habit: tracked.habit);
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) => CircleIconButton(
    tooltip: 'Back',
    icon: AppIcons.back,
    onPressed: () => context.pop(),
  );
}

class _PlanDetails extends ConsumerWidget {
  const _PlanDetails({
    required this.habitId,
    required this.report,
    required this.habit,
  });

  final int habitId;
  final PlanReport report;
  final Habit habit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final settings = ref.watch(currentSettingsProvider);
    final window = settings.dayWindow;
    final text = context.textTheme;
    final insets = MediaQuery.paddingOf(context);
    final current = report.current;
    final behindSaved = report.behindSavedCents;
    final aheadToSave = report.aheadToSaveCents;

    String money(double cents) =>
        AppFormat.money(math.max(0, cents), symbol: settings.currencySymbol);

    void openDay(LogicalDay day) {
      unawaited(HapticFeedback.selectionClick());
      openLogs(context, LogsQuery(habitId: habitId, from: day, to: day));
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: AppSpacing.page.copyWith(
          top: insets.top + AppSpacing.sm,
          bottom: insets.bottom + AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            ScrollReveal(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _BackButton(),
                  EditPill(habitId: habitId),
                ],
              ),
            ),
            ScrollReveal(
              index: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.xs,
                children: [
                  // "Regrettably." has to fit one line on the smallest phone.
                  MediaQuery.withClampedTextScaling(
                    maxScaleFactor: 1.5,
                    child: Text(
                      report.quitReached ? PlanCopy.quitTitle : PlanCopy.title,
                      style: text.headlineLarge,
                    ),
                  ),
                  Text(
                    PlanCopy.lead,
                    style: text.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            ScrollReveal(
              index: 2,
              child: PlanTotalsCard(
                habitId: habitId,
                totals: report.totals,
                habit: habit,
              ),
            ),
            if (report.behind.isNotEmpty)
              _Section(
                index: 3,
                title: PlanCopy.behindTitle,
                side: behindSaved == null
                    ? null
                    : PlanCopy.savedSide(money(behindSaved)),
                children: [
                  for (final group in report.behind) ...[
                    if (group.earlierUntil case final until?)
                      _GroupLabel(PlanCopy.earlierPlan(until))
                    else if (report.showsThisPlanLabel)
                      const _GroupLabel(PlanCopy.thisPlan),
                    for (final stage in group.stages)
                      StageRow(
                        report: stage,
                        kind: StageRowKind.behind,
                        habit: habit,
                        window: window,
                        onDay: openDay,
                      ),
                  ],
                ],
              ),
            if (current != null)
              _Section(
                index: 4,
                title: PlanCopy.youTitle,
                side: PlanCopy.stageOf(current.stage.number, report.stageCount),
                highlighted: true,
                children: [
                  CurrentStageCard(
                    report: current,
                    today: today,
                    nextLimit: report.ahead.firstOrNull?.stage.limit ?? 0,
                    onDay: openDay,
                  ),
                ],
              ),
            if (report.ahead.isNotEmpty)
              _Section(
                index: 5,
                title: PlanCopy.aheadTitle,
                side: aheadToSave == null
                    ? null
                    : PlanCopy.toSaveSide(money(aheadToSave)),
                children: [
                  for (final stage in report.ahead)
                    StageRow(
                      report: stage,
                      kind: StageRowKind.ahead,
                      habit: habit,
                      window: window,
                    ),
                ],
              ),
            ScrollReveal(
              index: 6,
              child: _FinishRow(report: report, habit: habit, today: today),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.index,
    required this.title,
    required this.side,
    required this.children,
    this.highlighted = false,
  });

  final int index;
  final String title;
  final String? side;
  final List<Widget> children;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final muted = context.colors.onSurfaceVariant;
    final side = this.side;
    final titleText = Text(
      title,
      style: text.labelSmall?.copyWith(
        color: muted,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.88,
      ),
    );
    final sideText = side == null
        ? null
        : Text(side, style: text.bodySmall?.copyWith(color: muted));
    return ScrollReveal(
      index: index,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.sm,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: context.hasLargeText
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [titleText, ?sideText],
                  )
                : Row(
                    spacing: AppSpacing.sm,
                    children: [
                      Expanded(child: titleText),
                      ?sideText,
                    ],
                  ),
          ),
          AnimatedSize(
            duration: AppMotion.swap,
            curve: AppMotion.swapCurve,
            alignment: Alignment.topCenter,
            child: Card(
              shape: highlighted
                  ? RoundedRectangleBorder(
                      borderRadius: AppRadius.card,
                      side: BorderSide(
                        color: context.colors.primaryContainer,
                        width: 2,
                      ),
                    )
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutterSm,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xs),
    child: Text(
      label,
      style: context.textTheme.labelSmall?.copyWith(
        color: context.colors.onSurfaceVariant,
      ),
    ),
  );
}

class _FinishRow extends StatelessWidget {
  const _FinishRow({
    required this.report,
    required this.habit,
    required this.today,
  });

  final PlanReport report;
  final Habit habit;
  final LogicalDay today;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final success = context.exhale.success.foreground;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        spacing: AppSpacing.gutterSm,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: success, width: 4),
            ),
            child: Icon(AppIcons.flag, size: 16, color: success),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  PlanCopy.finishTitle(habit.freeTitle, report.quitDay),
                  style: text.titleSmall,
                ),
                Text(
                  report.quitReached
                      ? PlanCopy.quitReached
                      : PlanCopy.daysToGo(report.quitDay.daysSince(today)),
                  style: text.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

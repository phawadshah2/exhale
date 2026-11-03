import 'dart:async';

import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/failure_message.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/app_snack_bar.dart';
import 'package:exhale/core/widgets/primary_button.dart';
import 'package:exhale/features/home/presentation/providers/stage_card_provider.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/plan/domain/services/plan_choices.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The words of a choice (Stages spec 5.3).
abstract final class StageChoiceCopy {
  static String name(PlanChoice choice) => switch (choice.kind) {
    ChoiceKind.realNumber => 'Start from your real number',
    ChoiceKind.slowDown => 'Slow down',
    ChoiceKind.keep => 'Keep my plan',
    ChoiceKind.startAgain => 'Start again from ${choice.limit}',
  };

  /// "9 a day, one fewer every 14 days"; Keep says "today" for "a day".
  static String detail(PlanChoice choice) {
    final amount = choice.kind == ChoiceKind.keep
        ? '${choice.limit} today'
        : '${choice.limit} a day';
    if (choice.dropsAboutDaily) return '$amount, dropping about every day';
    return '$amount, one fewer every ${choice.daysPerDrop.round()} days';
  }

  /// "No change", "3 weeks later" or "10 days later"; earlier when negative.
  static String change(PlanChoice choice) {
    final days = choice.changeDays;
    if (days == 0) return 'No change';
    final count = days.abs();
    final direction = days > 0 ? 'later' : 'earlier';
    if (count % 7 == 0) {
      final weeks = count ~/ 7;
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} $direction';
    }
    return '$count ${count == 1 ? 'day' : 'days'} $direction';
  }

  static String button(ChoiceKind selected) =>
      selected == ChoiceKind.keep ? 'Keep my plan' : 'Shake on it again';

  static String foot(ChoiceKind selected) => selected == ChoiceKind.keep
      ? "We'll look again if two more checks run over."
      : 'Past days keep their limits. Stages start again at 1.';
}

/// The shell of the review and reassess sheets: a heading, the figures
/// above, the choices, one button and the line under it.
class StageChoiceSheet extends ConsumerStatefulWidget {
  const StageChoiceSheet({
    required this.controller,
    required this.habitId,
    required this.card,
    required this.today,
    required this.choices,
    required this.title,
    required this.lead,
    required this.header,
    this.footer = const [],
    super.key,
  });

  final ScrollController controller;
  final int habitId;
  final StageCard card;

  /// The day the sheet opened; a new plan starts on it.
  final LogicalDay today;
  final List<PlanChoice> choices;
  final String title;
  final String lead;

  /// Figures between the lead and the choices.
  final List<Widget> header;

  /// Lines after the button's note.
  final List<Widget> footer;

  @override
  ConsumerState<StageChoiceSheet> createState() => _StageChoiceSheetState();
}

class _StageChoiceSheetState extends ConsumerState<StageChoiceSheet> {
  late ChoiceKind _selected = widget.choices.first.kind;
  bool _saving = false;

  PlanChoice get _choice =>
      widget.choices.firstWhere((choice) => choice.kind == _selected);

  void _select(ChoiceKind kind) {
    if (_saving || kind == _selected) return;
    unawaited(HapticFeedback.selectionClick());
    setState(() => _selected = kind);
  }

  Future<Result<void>> _answer() {
    final card = widget.card;
    if (_selected == ChoiceKind.keep) {
      return ref.read(answerStageCheckProvider)((
        habitId: widget.habitId,
        planStartDay: card.planStartDay,
        windowEndDay: card.windowEndDay,
      ));
    }
    final choice = _choice;
    return ref.read(answerWithNewPlanProvider)((
      habitId: widget.habitId,
      draft: PlanDraft(
        startDay: widget.today,
        startLimit: choice.limit,
        quitDay: choice.quitDay,
      ),
      planStartDay: card.planStartDay,
      windowEndDay: card.windowEndDay,
    ));
  }

  /// One save at a time; the sheet stays open when it fails.
  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    unawaited(HapticFeedback.selectionClick());
    final result = await _answer();
    if (!mounted) return;
    switch (result) {
      case Success():
        Navigator.of(context).pop();
      case FailureResult(:final failure):
        setState(() => _saving = false);
        showAppSnackBar(
          context,
          message: failureMessage(failure),
          tone: SnackTone.danger,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final muted = text.bodyMedium?.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    // Follows the day for a sheet left open past midnight.
    ref.watch(todayProvider);
    return ListView(
      controller: widget.controller,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      children: [
        Text(widget.title, style: text.titleLarge),
        const SizedBox(height: 4),
        Text(widget.lead, style: muted),
        const SizedBox(height: AppSpacing.md),
        ...widget.header,
        const SizedBox(height: AppSpacing.md),
        Semantics(
          container: true,
          label: 'Choose how to go on',
          child: Column(
            spacing: AppSpacing.sm,
            children: [
              for (final choice in widget.choices)
                _ChoiceTile(
                  choice: choice,
                  selected: choice.kind == _selected,
                  onTap: () => _select(choice.kind),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        PrimaryButton(
          label: StageChoiceCopy.button(_selected),
          isBusy: _saving,
          onPressed: () => unawaited(_save()),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          StageChoiceCopy.foot(_selected),
          style: text.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        if (widget.footer.isNotEmpty) const SizedBox(height: AppSpacing.md),
        ...widget.footer,
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final PlanChoice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final name = StageChoiceCopy.name(choice);
    final detail = StageChoiceCopy.detail(choice);
    final date = AppFormat.monthDay(choice.quitDay);
    final change = StageChoiceCopy.change(choice);
    final muted = text.bodySmall?.copyWith(color: colors.onSurfaceVariant);

    final words = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: text.titleSmall),
        Text(detail, style: muted),
      ],
    );
    final when = Column(
      crossAxisAlignment: context.hasLargeText
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Text(
          date,
          style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(change, style: muted),
      ],
    );

    // One node for VoiceOver: name, detail, date and change together.
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: '$name. $detail. Quit date $date. $change.',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.all(AppSpacing.gutterSm),
          decoration: BoxDecoration(
            color: context.exhale.inset,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? colors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.gutterSm,
            children: [
              _Radio(selected: selected),
              Expanded(
                child: context.hasLargeText
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: AppSpacing.xs,
                        children: [words, when],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: AppSpacing.sm,
                        children: [
                          Expanded(child: words),
                          when,
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 22,
      height: 22,
      margin: const EdgeInsets.only(top: 1),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? colors.primary : colors.outline,
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primary,
                ),
              ),
            )
          : null,
    );
  }
}

/// A figure with its label under it, in a tinted tile.
class StageFigure extends StatelessWidget {
  const StageFigure({required this.value, required this.label, super.key});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return Semantics(
      container: true,
      label: '$value $label',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gutterSm,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: context.exhale.inset,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              label,
              style: text.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// [figures] in a row, or stacked at large text sizes.
class StageFigures extends StatelessWidget {
  const StageFigures({required this.figures, super.key});

  final List<StageFigure> figures;

  @override
  Widget build(BuildContext context) {
    if (context.hasLargeText) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.sm,
        children: figures,
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.sm,
        children: [for (final figure in figures) Expanded(child: figure)],
      ),
    );
  }
}

import 'dart:async';

import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/status_badge.dart';
import 'package:exhale/features/logs/domain/logs_selection.dart';
import 'package:exhale/features/logs/presentation/providers/logs_providers.dart';
import 'package:exhale/features/logs/presentation/widgets/logs_calendar_card.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:exhale/features/tracking/domain/entities/trigger_breakdown.dart';
import 'package:exhale/features/tracking/presentation/trigger_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The period's totals, its triggers as a bar, and a filter chip for each.
class LogsTriggerCard extends StatelessWidget {
  const LogsTriggerCard({
    required this.selection,
    required this.view,
    required this.today,
    required this.onTrigger,
    super.key,
  });

  final LogsSelection selection;
  final LogsView view;
  final LogicalDay today;
  final ValueChanged<Trigger> onTrigger;

  String get _label => LogsCalendarCard.ago(selection, today);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final breakdown = view.breakdown;
    final selected = selection.trigger;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.gutterSm,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: AppSpacing.sm,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _label,
                        style: text.labelMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      if (view.hasPlanDays)
                        _Allowed(view: view)
                      else
                        Text('Before your plan', style: text.titleMedium),
                    ],
                  ),
                ),
                if (view.hasPlanDays) _Pill(under: view.stats.underBy),
              ],
            ),
            if (breakdown.total > 0)
              _Bar(
                breakdown: breakdown,
                selected: selected,
                label: 'Triggers for $_label',
              ),
            if (breakdown.total > 0 || selected != null)
              _Chips(
                breakdown: breakdown,
                selected: selected,
                onTrigger: onTrigger,
              ),
          ],
        ),
      ),
    );
  }
}

class _Allowed extends StatelessWidget {
  const _Allowed({required this.view});

  final LogsView view;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final stats = view.stats;
    final soFar = stats.allowedByToday == stats.allowed
        ? ''
        : ' (${stats.allowedByToday} so far)';
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${stats.logged}',
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          TextSpan(
            text: ' / ${stats.allowed}$soFar allowed',
            style: text.titleSmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.under});

  final int under;

  @override
  Widget build(BuildContext context) => under >= 0
      ? StatusBadge(label: '$under under', colors: context.exhale.success)
      : StatusBadge(label: '${-under} over', colors: context.exhale.danger);
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.breakdown,
    required this.selected,
    required this.label,
  });

  final TriggerBreakdown breakdown;
  final Trigger? selected;
  final String label;

  static const double _dimmed = 0.3;

  @override
  Widget build(BuildContext context) {
    Color tint(Trigger trigger) {
      final color = trigger.tint(context);
      return selected == null || selected == trigger
          ? color
          : color.withValues(alpha: _dimmed);
    }

    final none = context.colors.onSurfaceVariant;
    return Semantics(
      image: true,
      label: label,
      excludeSemantics: true,
      child: ClipRRect(
        key: const Key('logs-trigger-bar'),
        borderRadius: AppRadius.pill,
        child: SizedBox(
          height: 10,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 2,
            children: [
              for (final share in breakdown.shares)
                Expanded(
                  flex: share.count,
                  child: ColoredBox(color: tint(share.trigger)),
                ),
              if (breakdown.noTrigger > 0)
                Expanded(
                  flex: breakdown.noTrigger,
                  child: ColoredBox(
                    color: selected == null
                        ? none
                        : none.withValues(alpha: _dimmed),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chips extends StatelessWidget {
  const _Chips({
    required this.breakdown,
    required this.selected,
    required this.onTrigger,
  });

  final TriggerBreakdown breakdown;
  final Trigger? selected;
  final ValueChanged<Trigger> onTrigger;

  @override
  Widget build(BuildContext context) {
    final picked = selected;
    final shares = breakdown.shares;
    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        for (final share in shares)
          _TriggerChip(
            trigger: share.trigger,
            count: share.count,
            selected: share.trigger == picked,
            onTrigger: onTrigger,
          ),
        if (picked != null && shares.every((share) => share.trigger != picked))
          _TriggerChip(
            trigger: picked,
            count: 0,
            selected: true,
            onTrigger: onTrigger,
          ),
        if (breakdown.noTrigger > 0) _NoneChip(count: breakdown.noTrigger),
      ],
    );
  }
}

class _TriggerChip extends StatelessWidget {
  const _TriggerChip({
    required this.trigger,
    required this.count,
    required this.selected,
    required this.onTrigger,
  });

  final Trigger trigger;
  final int count;
  final bool selected;
  final ValueChanged<Trigger> onTrigger;

  @override
  Widget build(BuildContext context) {
    final tint = trigger.tint(context);
    final textTint = trigger.textTint(context);
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          unawaited(HapticFeedback.selectionClick());
          onTrigger(trigger);
        },
        child: _ChipBody(
          label: '${trigger.label} $count',
          fill: selected ? textTint : tint.withValues(alpha: 0.1),
          border: selected ? textTint : tint.withValues(alpha: 0.35),
          color: selected ? context.colors.surface : textTint,
        ),
      ),
    );
  }
}

class _NoneChip extends StatelessWidget {
  const _NoneChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => _ChipBody(
    label: 'None $count',
    border: context.colors.outlineVariant,
    color: context.colors.onSurfaceVariant,
  );
}

class _ChipBody extends StatelessWidget {
  const _ChipBody({
    required this.label,
    required this.border,
    required this.color,
    this.fill,
  });

  final String label;
  final Color? fill;
  final Color border;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // The pill stays small; the touch is 44 pt.
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Center(
        widthFactor: 1,
        child: Container(
          constraints: const BoxConstraints(minHeight: 34),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: ShapeDecoration(
            color: fill,
            shape: StadiumBorder(side: BorderSide(color: border)),
          ),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: context.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

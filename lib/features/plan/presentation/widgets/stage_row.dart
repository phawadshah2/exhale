import 'dart:async';
import 'dart:math' as math;

import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/plan/domain/services/plan_report.dart';
import 'package:exhale/features/plan/presentation/plan_copy.dart';
import 'package:exhale/features/plan/presentation/widgets/stage_ring.dart';
import 'package:exhale/features/settings/domain/entities/day_window.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:exhale/features/tracking/presentation/trigger_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum StageRowKind { behind, ahead }

/// A stage's money line: the figure and what it is. At large text it joins
/// the text column, so the dates keep their width.
@immutable
class StageMoney {
  const StageMoney({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;
}

/// A ring, the stage's name and dates, its money and whatever ends the row.
class StageHeader extends StatelessWidget {
  const StageHeader({
    required this.ring,
    required this.title,
    required this.dates,
    required this.money,
    this.trailing,
    super.key,
  });

  final Widget ring;
  final Widget title;
  final String dates;
  final StageMoney? money;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final muted = context.colors.onSurfaceVariant;
    final money = this.money;
    final stacked = context.hasLargeText;
    final trailing = this.trailing;
    return Row(
      spacing: AppSpacing.gutterSm,
      children: [
        ring,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              Text(dates, style: text.bodySmall?.copyWith(color: muted)),
              if (stacked && money != null)
                Text.rich(
                  TextSpan(
                    text: money.value,
                    style: text.titleSmall?.copyWith(
                      color: money.color,
                      fontWeight: FontWeight.w700,
                    ),
                    children: [
                      TextSpan(
                        text: ' ${money.label}',
                        style: text.bodySmall?.copyWith(color: muted),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (!stacked && money != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                money.value,
                style: text.titleSmall?.copyWith(
                  color: money.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(money.label, style: text.labelSmall?.copyWith(color: muted)),
            ],
          ),
        ?trailing,
      ],
    );
  }
}

/// A stage behind or ahead of today. Closed until tapped; each opens and
/// closes on its own.
class StageRow extends ConsumerStatefulWidget {
  const StageRow({
    required this.report,
    required this.kind,
    required this.habit,
    required this.window,
    super.key,
  });

  final StageReport report;
  final StageRowKind kind;
  final Habit habit;
  final DayWindow? window;

  @override
  ConsumerState<StageRow> createState() => _StageRowState();
}

class _StageRowState extends ConsumerState<StageRow> {
  static const Duration _openDuration = Duration(milliseconds: 250);

  bool _open = false;

  void _toggle() {
    unawaited(HapticFeedback.selectionClick());
    setState(() => _open = !_open);
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final ahead = widget.kind == StageRowKind.ahead;
    final colors = context.colors;
    final symbol = ref.watch(currentSettingsProvider).currencySymbol;
    final cents = ahead ? report.toSaveCents : report.savedCents;
    final money = cents == null
        ? null
        : StageMoney(
            value: AppFormat.money(math.max(0, cents), symbol: symbol),
            label: ahead ? PlanCopy.toSave : PlanCopy.saved,
            color: ahead
                ? colors.onSurfaceVariant
                : context.exhale.success.foreground,
          );
    final dates = PlanCopy.range(report.stage.startDay, report.lastDay);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : _openDuration;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: _open,
          label:
              '${PlanCopy.stage(report.stage.number)}, '
              '${report.stage.limit} a day, $dates'
              '${money == null ? '' : ', ${money.value} ${money.label}'}',
          excludeSemantics: true,
          onTap: _toggle,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggle,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 60),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: StageHeader(
                  ring: StageRing(report: report, ahead: ahead),
                  title: Text(
                    PlanCopy.stage(report.stage.number),
                    style: context.textTheme.titleSmall,
                  ),
                  dates: dates,
                  money: money,
                  trailing: AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: duration,
                    child: Icon(
                      AppIcons.chevronDown,
                      size: 16,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: duration,
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: _open
              ? _StagePanel(
                  report: report,
                  kind: widget.kind,
                  habit: widget.habit,
                  window: widget.window,
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _StagePanel extends ConsumerWidget {
  const _StagePanel({
    required this.report,
    required this.kind,
    required this.habit,
    required this.window,
  });

  final StageReport report;
  final StageRowKind kind;
  final Habit habit;
  final DayWindow? window;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final over = context.exhale.danger.foreground;
    final mostly = report.mostly;
    final pace = PlanCopy.paceEvery(window, report.stage.limit);
    final unitsTitle = PlanCopy.unitsTitle(habit);

    final stats = switch (kind) {
      StageRowKind.behind => [
        _Stat(
          unitsTitle,
          PlanCopy.usedOf(report.used, report.allowed),
          color: report.isOverAllowed ? over : null,
        ),
        _Stat(
          PlanCopy.daysOver,
          PlanCopy.overOf(report.daysOver, report.days),
          color: report.daysOver > 0 ? over : null,
        ),
        _Stat(PlanCopy.average, PlanCopy.perDay(report.average)),
        if (mostly != null) _Stat(PlanCopy.mostly, mostly.label),
      ],
      StageRowKind.ahead => [
        _Stat(unitsTitle, PlanCopy.allowed(report.allowed)),
        if (pace != null) _Stat(PlanCopy.pace, pace),
        if (report.toAvoid > 0)
          _Stat(PlanCopy.toAvoid, PlanCopy.amount(report.toAvoid, habit)),
        _Stat(
          PlanCopy.starts,
          PlanCopy.startsIn(report.stage.startDay.daysSince(today)),
        ),
      ],
    };
    final note = report.note;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.gutterSm),
      decoration: BoxDecoration(
        color: context.exhale.inset,
        borderRadius: AppRadius.inner,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          if (context.hasLargeText)
            ...stats
          else
            for (var row = 0; row < stats.length; row += 2)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.gutterSm,
                children: [
                  Expanded(child: stats[row]),
                  Expanded(
                    child: row + 1 < stats.length
                        ? stats[row + 1]
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
          if (note != null)
            Text(
              PlanCopy.note(note, daysOver: report.daysOver),
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, {this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 1,
      children: [
        Text(
          label,
          style: text.labelSmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        Text(value, style: text.titleSmall?.copyWith(color: color)),
      ],
    );
  }
}

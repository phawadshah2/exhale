import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_motion.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/smooth_switcher.dart';
import 'package:exhale/features/home/presentation/providers/next_log_timer_provider.dart';
import 'package:exhale/features/home/presentation/widgets/history/chart_paint.dart';
import 'package:exhale/features/logs/domain/day_rail.dart';
import 'package:exhale/features/logs/domain/logs_selection.dart';
import 'package:exhale/features/logs/presentation/providers/logs_providers.dart';
import 'package:exhale/features/logs/presentation/widgets/logs_calendar_card.dart';
import 'package:exhale/features/plan/presentation/widgets/stage_ring.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/tracking/domain/entities/daily_progress.dart';
import 'package:exhale/features/tracking/domain/entities/habit_log.dart';
import 'package:exhale/features/tracking/domain/entities/limit_status.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:exhale/features/tracking/presentation/limit_status_ui.dart';
import 'package:exhale/features/tracking/presentation/trigger_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The selected day: its count ring and its rail, placed by time.
class LogsRailCard extends ConsumerWidget {
  const LogsRailCard({
    required this.habitId,
    required this.selection,
    required this.view,
    required this.today,
    required this.onEdit,
    required this.onDelete,
    required this.onSelect,
    super.key,
  });

  final int habitId;
  final LogsSelection selection;
  final LogsView view;
  final LogicalDay today;
  final ValueChanged<HabitLog> onEdit;
  final Future<void> Function(HabitLog log) onDelete;

  /// A day picked from a range's list, which opens its week.
  final ValueChanged<LogicalDay> onSelect;

  /// 28 pt, and 1 pt more for every 5 minutes, up to 120.
  static double gapHeight(Duration gap) =>
      (28 + gap.inMinutes / 5).clamp(28.0, 120.0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = context.textTheme;
    final day = selection.selected;
    final entry = view.dayOf(day);
    final isToday = day == today;
    final trigger = selection.trigger;
    // Only today listens, as the timer ticks each second.
    final next = isToday
        ? ref.watch(
            nextLogTimerProvider(habitId).select((timer) {
              return timer == null || timer.isPast ? null : timer.guide.next;
            }),
          )
        : null;

    if (trigger != null || selection.isRange) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: AppSpacing.card,
          child: SmoothSwitcher(
            resize: true,
            child: trigger == null
                ? _RangeDays(
                    key: ValueKey('days-${selection.period}'),
                    view: view,
                    onSelect: onSelect,
                  )
                : _RangeLogs(
                    key: ValueKey('${selection.period}-${trigger.name}'),
                    selection: selection,
                    view: view,
                    trigger: trigger,
                    today: today,
                    onEdit: onEdit,
                    onDelete: onDelete,
                  ),
          ),
        ),
      );
    }

    final rail = DayRail.build(
      logs: entry.logs.reversed.toList(),
      limit: entry.limit,
      window: ref.watch(currentSettingsProvider).dayWindow,
      day: day,
      isToday: isToday,
      next: next,
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.card,
        child: SmoothSwitcher(
          resize: true,
          child: Column(
            key: ValueKey('rail-$day'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.gutterSm,
            children: [
              _DayHeader(entry: entry, isToday: isToday),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, row) in rail.indexed)
                    _entry(row, isLast: i == rail.length - 1, isToday: isToday),
                ],
              ),
              Divider(height: 1, color: colors.outlineVariant),
              Text(
                'Forgot one? Tap + at the top to add it to this day. '
                "I'll pretend it was on time.",
                style: text.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _entry(
    RailEntry row, {
    required bool isLast,
    required bool isToday,
  }) => switch (row) {
    RailWake(:final at) => _MarkRow(
      label: 'Woke up',
      side: AppFormat.time(at),
      line: isLast ? null : _LineStyle.solid,
    ),
    RailBed(:final at) => _MarkRow(
      label: 'Bed',
      side: AppFormat.time(at),
      line: isLast ? null : _LineStyle.solid,
    ),
    RailLimitReached(:final limit) => _MarkRow(
      label: 'Limit reached here',
      side: '$limit of $limit',
      line: _LineStyle.solid,
      tone: _MarkTone.danger,
    ),
    RailNext(:final at) => _MarkRow(
      label: 'Next on schedule',
      side: AppFormat.time(at),
      line: _LineStyle.dashed,
      tone: _MarkTone.accent,
    ),
    RailGap(:final gap, :final longest) => _GapRow(
      label: longest
          ? '${AppFormat.hoursMinutes(gap)}. '
                '${isToday ? 'Longest today. Frame it.' : 'Longest that day.'}'
          : AppFormat.hoursMinutes(gap),
      height: gapHeight(gap),
      longest: longest,
    ),
    RailNothingYet() => const _GapRow(
      label: 'Nothing here yet. Keep it that way.',
      height: 44,
      line: _LineStyle.dashed,
    ),
    RailThenNothing() => const _GapRow(
      label: 'Then nothing. Well done, or asleep.',
      height: 36,
    ),
    RailNothingLogged() => const _GapRow(
      label: 'Nothing logged. Well done, or forgot.',
      height: 36,
    ),
    RailLog(:final log, :final over) => _LogRow(
      log: log,
      over: over,
      onEdit: onEdit,
      onDelete: onDelete,
    ),
  };
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.entry, required this.isToday});

  final LogsDay entry;
  final bool isToday;

  (String, Color) _count(BuildContext context) {
    final exhale = context.exhale;
    final count = entry.count;
    final progress = entry.progress;
    if (progress == null) {
      return (
        '$count logged · before your plan',
        context.colors.onSurfaceVariant,
      );
    }
    final limit = progress.limit;
    final base = '$count of $limit';
    return switch (progress.status) {
      LimitStatus.over => (
        '$base · ${progress.overBy} over',
        exhale.danger.foreground,
      ),
      _ when isToday => (
        '$base · ${progress.remaining} left',
        exhale.success.foreground,
      ),
      LimitStatus.at => ('$base · at limit', exhale.warning.foreground),
      LimitStatus.under => (base, exhale.success.foreground),
    };
  }

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final date = AppFormat.shortWeekdayDate(entry.day);
    final (count, color) = _count(context);
    final progress = entry.progress;
    return Row(
      spacing: AppSpacing.gutterSm,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isToday ? 'Today · $date' : date, style: text.titleMedium),
              Text(
                count,
                style: text.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (progress != null)
          LogsCountRing(limit: progress.limit, count: progress.count),
      ],
    );
  }
}

/// The day's count against its limit as a ring, filling on arrival and
/// whenever the count changes.
class LogsCountRing extends StatelessWidget {
  const LogsCountRing({
    required this.limit,
    required this.count,
    this.size = 52,
    super.key,
  });

  final double size;
  final int limit;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final progress = DailyProgress(
      day: LogicalDay(2000, 1, 1),
      count: count,
      limit: limit,
    );
    final atZero = limit == 0 && count == 0;
    final color = atZero
        ? context.exhale.success.solid
        : progress.status.barColor(context);
    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: atZero ? 1 : progress.usedFraction),
        duration: AppMotion.fill,
        curve: AppMotion.fillCurve,
        builder: (context, fill, _) => SizedBox.square(
          dimension: size,
          child: CustomPaint(
            painter: StageRingPainter(
              fill: fill,
              strokeWidth: size / 10.4,
              color: color,
              track: colors.surfaceContainerHigh,
              dashed: false,
            ),
            child: Center(
              child: MediaQuery.withNoTextScaling(
                child: Text(
                  '$count',
                  style:
                      (size >= 40
                              ? context.textTheme.titleSmall
                              : context.textTheme.labelSmall)
                          ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One row for each day of a range: its count against its limit. A row opens
/// that day's week.
class _RangeDays extends StatelessWidget {
  const _RangeDays({required this.view, required this.onSelect, super.key});

  final LogsView view;
  final ValueChanged<LogicalDay> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final muted = text.bodySmall?.copyWith(color: colors.onSurfaceVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            children: [
              Text('Days in this range', style: text.titleMedium),
              Text('${view.days.length} days', style: muted),
            ],
          ),
        ),
        for (final entry in view.days)
          _DayRow(entry: entry, onTap: () => onSelect(entry.day)),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.entry, required this.onTap});

  final LogsDay entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final date = AppFormat.shortWeekdayDate(entry.day);
    final limit = entry.limit;
    final count = limit == null
        ? '${entry.count} logged'
        : '${entry.count} of $limit';
    return Semantics(
      button: true,
      label: '$date, $count. Opens its week.',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.outlineVariant)),
          ),
          child: Row(
            spacing: AppSpacing.sm,
            children: [
              Expanded(child: Text(date, style: text.bodyMedium)),
              Text(
                count,
                style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
              if (limit != null)
                LogsCountRing(limit: limit, count: entry.count, size: 30)
              else
                const SizedBox.square(dimension: 30),
              Icon(
                AppIcons.chevronRight,
                size: 14,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Every log with the filter's trigger in the week or range, a heading for
/// each day. A very long range lists its latest [_cap] logs.
class _RangeLogs extends StatelessWidget {
  const _RangeLogs({
    required this.selection,
    required this.view,
    required this.trigger,
    required this.today,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final LogsSelection selection;
  final LogsView view;
  final Trigger trigger;
  final LogicalDay today;
  final ValueChanged<HabitLog> onEdit;
  final Future<void> Function(HabitLog log) onDelete;

  static const int _cap = 200;

  bool _matches(HabitLog log) => log.trigger == trigger;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final days = [
      for (final entry in view.days)
        if (entry.logs.any(_matches)) entry,
    ];
    final total = days.fold<int>(
      0,
      (sum, entry) => sum + entry.logs.where(_matches).length,
    );
    final heading = selection.isRange
        ? 'in this range'
        : LogsCalendarCard.ago(selection, today).toLowerCase();
    final label = trigger.label;
    var left = _cap;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.gutterSm,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.sm,
          children: [
            Text(label, style: text.titleMedium),
            Text(
              '$total ${total == 1 ? 'log' : 'logs'} $heading',
              style: text.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (days.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(
              'No $label logs $heading.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          )
        else
          for (final entry in days)
            if (left > 0)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.sm,
                children: [
                  Text(
                    AppFormat.shortWeekdayDate(entry.day),
                    style: text.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  for (final (i, log) in entry.logs.indexed)
                    if (_matches(log) && left-- > 0)
                      _LogRow(
                        log: log,
                        // Newest first, so the oldest log has the highest
                        // index.
                        over:
                            entry.limit != null &&
                            entry.logs.length - 1 - i >= entry.limit!,
                        onEdit: onEdit,
                        onDelete: onDelete,
                      ),
                ],
              ),
        if (total > _cap)
          Text(
            'Showing the latest $_cap.',
            textAlign: TextAlign.center,
            style: text.labelMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
      ],
    );
  }
}

enum _LineStyle { solid, dashed }

enum _MarkTone { muted, danger, accent }

/// The rail's vertical line, centred under a 40 pt lead.
class _RailLine extends StatelessWidget {
  const _RailLine({required this.style, this.top = 0});

  static const double width = 2;
  static const double _left = (_RailRow.leadWidth - width) / 2;

  final _LineStyle style;
  final double top;

  @override
  Widget build(BuildContext context) => Positioned(
    left: _left,
    width: width,
    top: top,
    bottom: 0,
    child: CustomPaint(
      painter: _LinePainter(
        dashed: style == _LineStyle.dashed,
        color: style == _LineStyle.dashed
            ? context.colors.outline
            : context.colors.outlineVariant,
      ),
    ),
  );
}

class _LinePainter extends CustomPainter {
  const _LinePainter({required this.dashed, required this.color});

  final bool dashed;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final line = Path()
      ..moveTo(x, 0)
      ..lineTo(x, size.height);
    canvas.drawPath(
      dashed ? dashedPath(line, dash: 4) : line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width,
    );
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.dashed != dashed || old.color != color;
}

class _RailRow extends StatelessWidget {
  const _RailRow({required this.lead, required this.child, this.line});

  static const double leadWidth = 40;

  final Widget lead;
  final Widget child;
  final _RailLine? line;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ?line,
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.gutterSm,
        children: [
          SizedBox(
            width: leadWidth,
            child: Center(child: lead),
          ),
          Expanded(child: child),
        ],
      ),
    ],
  );
}

class _MarkRow extends StatelessWidget {
  const _MarkRow({
    required this.label,
    required this.side,
    this.line,
    this.tone = _MarkTone.muted,
  });

  static const double _dot = 12;
  static const double _dotMargin = 4;

  final String label;
  final String side;
  final _LineStyle? line;
  final _MarkTone tone;

  @override
  Widget build(BuildContext context) {
    final muted = context.colors.onSurfaceVariant;
    final danger = context.exhale.danger.foreground;
    final dot = switch (tone) {
      _MarkTone.muted => muted,
      _MarkTone.danger => danger,
      _MarkTone.accent => context.colors.primary,
    };
    final color = tone == _MarkTone.danger ? danger : muted;
    final style = context.textTheme.labelMedium;
    final rail = line;
    return _RailRow(
      line: rail == null
          ? null
          : _RailLine(style: rail, top: _dot + _dotMargin * 2),
      lead: Container(
        width: _dot,
        height: _dot,
        margin: const EdgeInsets.symmetric(vertical: _dotMargin),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: dot, width: 2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: AppSpacing.sm,
          children: [
            Text(
              label,
              style: style?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
            Text(
              side,
              style: style?.copyWith(color: color, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }
}

class _GapRow extends StatelessWidget {
  const _GapRow({
    required this.label,
    required this.height,
    this.longest = false,
    this.line = _LineStyle.solid,
  });

  final String label;
  final double height;
  final bool longest;
  final _LineStyle line;

  @override
  Widget build(BuildContext context) => _RailRow(
    line: _RailLine(style: line),
    lead: const SizedBox.shrink(),
    child: Container(
      constraints: BoxConstraints(minHeight: height),
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: context.textTheme.labelMedium?.copyWith(
          color: longest
              ? context.exhale.success.foreground
              : context.colors.onSurfaceVariant,
          fontWeight: longest ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    ),
  );
}

class _LogRow extends StatelessWidget {
  const _LogRow({
    required this.log,
    required this.over,
    required this.onEdit,
    required this.onDelete,
  });

  final HabitLog log;
  final bool over;
  final ValueChanged<HabitLog> onEdit;
  final Future<void> Function(HabitLog log) onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final danger = context.exhale.danger;
    final trigger = log.trigger;
    final time = AppFormat.time(log.loggedAt);
    final note = log.note ?? (over ? 'Over the limit. Noted.' : 'No note');

    return Dismissible(
      key: ValueKey(log.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await onDelete(log);
        return false;
      },
      background: Align(
        alignment: Alignment.centerRight,
        child: Container(
          width: 84,
          color: danger.solid,
          alignment: Alignment.center,
          child: Icon(AppIcons.delete, size: 18, color: danger.onSolid),
        ),
      ),
      child: Semantics(
        container: true,
        button: true,
        label: '$time. Tap to edit, swipe to delete.',
        excludeSemantics: true,
        onTap: () => onEdit(log),
        customSemanticsActions: {
          const CustomSemanticsAction(label: 'Delete'): () => onDelete(log),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onEdit(log),
          child: ColoredBox(
            color: Theme.of(context).cardTheme.color ?? colors.surface,
            child: _RailRow(
              lead: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: over ? danger.soft : colors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  trigger?.icon ?? AppIcons.clock,
                  size: 20,
                  color: trigger?.tint(context) ?? colors.onSurfaceVariant,
                ),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpacing.sm,
                      children: [
                        Text(
                          time,
                          style: text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          trigger?.label ?? 'No trigger',
                          style: text.labelMedium?.copyWith(
                            color:
                                trigger?.textTint(context) ??
                                colors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      note,
                      style: text.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

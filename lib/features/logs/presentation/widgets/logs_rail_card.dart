import 'dart:math' as math;

import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/home/presentation/providers/next_log_timer_provider.dart';
import 'package:exhale/features/home/presentation/widgets/history/chart_paint.dart';
import 'package:exhale/features/logs/domain/day_rail.dart';
import 'package:exhale/features/logs/domain/logs_selection.dart';
import 'package:exhale/features/logs/presentation/providers/logs_providers.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/tracking/domain/entities/habit_log.dart';
import 'package:exhale/features/tracking/domain/entities/limit_status.dart';
import 'package:exhale/features/tracking/presentation/trigger_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The selected day: its count, its slots and its rail, placed by time.
class LogsRailCard extends ConsumerWidget {
  const LogsRailCard({
    required this.habitId,
    required this.selection,
    required this.view,
    required this.today,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final int habitId;
  final LogsSelection selection;
  final LogsView view;
  final LogicalDay today;
  final ValueChanged<HabitLog> onEdit;
  final Future<void> Function(HabitLog log) onDelete;

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

    final rail = DayRail.build(
      logs: entry.logs.reversed.toList(),
      limit: entry.limit,
      window: ref.watch(currentSettingsProvider).dayWindow,
      day: day,
      isToday: isToday,
      next: next,
      filter: trigger,
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.gutterSm,
          children: [
            _DayHeader(entry: entry, isToday: isToday),
            if (trigger != null && rail.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(
                  'No ${trigger.label} logs this day.',
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: trigger == null ? 0 : AppSpacing.sm,
                children: [
                  for (final (i, row) in rail.indexed)
                    _entry(row, isLast: i == rail.length - 1, isToday: isToday),
                ],
              ),
            if (trigger == null) ...[
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
          ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        // Wraps at large text sizes instead of overflowing.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.sm,
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
        if (progress != null && (progress.limit > 0 || progress.count > 0))
          LogsSlotBar(limit: progress.limit, count: progress.count),
      ],
    );
  }
}

/// One slot for each of the limit or the count, whichever is more.
class LogsSlotBar extends StatelessWidget {
  const LogsSlotBar({required this.limit, required this.count, super.key});

  final int limit;
  final int count;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: _SlotPainter.height,
      child: CustomPaint(
        painter: _SlotPainter(
          limit: limit,
          count: count,
          used: context.colors.primaryContainer,
          over: context.exhale.danger.solid,
          unused: context.colors.surfaceContainerHigh,
        ),
      ),
    ),
  );
}

class _SlotPainter extends CustomPainter {
  const _SlotPainter({
    required this.limit,
    required this.count,
    required this.used,
    required this.over,
    required this.unused,
  });

  static const double height = 6;
  static const double _gap = 4;

  final int limit;
  final int count;
  final Color used;
  final Color over;
  final Color unused;

  @override
  void paint(Canvas canvas, Size size) {
    final slots = math.max(limit, count);
    // At 80 slots a 4 pt gap would leave no slot to draw.
    final gap = math.min(_gap, size.width / slots / 4);
    final width = (size.width - gap * (slots - 1)) / slots;
    for (var i = 0; i < slots; i++) {
      final color = i >= limit
          ? over
          : i < count
          ? used
          : unused;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(i * (width + gap), 0, width, height),
          const Radius.circular(height / 2),
        ),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_SlotPainter old) =>
      old.limit != limit ||
      old.count != count ||
      old.used != used ||
      old.over != over ||
      old.unused != unused;
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
            color: colors.surfaceContainerLow,
            child: _RailRow(
              lead: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: over ? danger.soft : colors.surfaceContainerHighest,
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

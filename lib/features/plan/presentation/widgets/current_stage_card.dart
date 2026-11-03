import 'dart:math' as math;

import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/fill_in.dart';
import 'package:exhale/features/plan/domain/services/plan_report.dart';
import 'package:exhale/features/plan/presentation/dot_layout.dart';
import 'package:exhale/features/plan/presentation/plan_copy.dart';
import 'package:exhale/features/plan/presentation/widgets/stage_ring.dart';
import 'package:exhale/features/plan/presentation/widgets/stage_row.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/tracking/domain/entities/daily_progress.dart';
import 'package:exhale/features/tracking/domain/entities/limit_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DayDot { under, atLimit, over, today, ahead }

/// The stage today is in, always open: a ring per day up to 14 days, then a
/// dot per day, with the key and how the stage is going.
class CurrentStageCard extends ConsumerWidget {
  const CurrentStageCard({
    required this.report,
    required this.today,
    required this.nextLimit,
    super.key,
  });

  /// The most days that still show as rings.
  static const int maxRingDays = 14;

  final StageReport report;
  final LogicalDay today;

  /// The limit after this stage; 0 on the last one.
  final int nextLimit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = context.textTheme;
    final symbol = ref.watch(currentSettingsProvider).currencySymbol;
    String money(double cents) =>
        AppFormat.money(math.max(0, cents), symbol: symbol);

    final saved = report.savedCents;
    final toSave = report.toSaveCents;
    final image = PlanCopy.daysImage(
      days: report.days,
      limit: report.stage.limit,
      over: report.daysOver,
      dayNumber: report.stage.dayNumberOf(today),
    );
    final days = report.days <= maxRingDays
        ? Semantics(
            container: true,
            image: true,
            label: image,
            excludeSemantics: true,
            child: _DayRings(report: report, today: today),
          )
        : _DayDots(report: report, today: today, semanticLabel: image);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.gutterSm,
        children: [
          StageHeader(
            ring: ExcludeSemantics(child: StageRing(report: report, size: 56)),
            title: Row(
              spacing: 6,
              children: [
                Flexible(
                  child: Text(
                    PlanCopy.stage(report.stage.number),
                    style: text.titleSmall,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: AppRadius.pill,
                  ),
                  child: Text(
                    PlanCopy.now,
                    style: text.labelSmall?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            dates: PlanCopy.currentRange(report, today),
            money: saved == null || toSave == null
                ? null
                : StageMoney(
                    value: money(saved),
                    // A stage at the baseline has nothing to save of.
                    label: toSave > 0
                        ? PlanCopy.ofToSave(money(toSave))
                        : PlanCopy.saved,
                    color: context.exhale.success.foreground,
                  ),
          ),
          if (MediaQuery.disableAnimationsOf(context))
            days
          else
            FillIn(child: days),
          const _Key(),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.outlineVariant)),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 2,
                children: [
                  Text(
                    PlanCopy.usedAndOver(
                      report.used,
                      report.allowed,
                      report.daysOver,
                    ),
                    style: text.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    PlanCopy.drops(
                      nextLimit,
                      report.lastDay.daysSince(today) + 1,
                    ),
                    style: text.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(BuildContext context, LimitStatus status) =>
    switch (status) {
      LimitStatus.under => context.colors.primaryContainer,
      LimitStatus.at => context.exhale.warning.solid,
      LimitStatus.over => context.exhale.danger.solid,
    };

/// Seven rings to a row. Fixed size, as the row above says the same thing.
class _DayRings extends StatelessWidget {
  const _DayRings({required this.report, required this.today});

  static const int _perRow = 7;
  static const double _ring = 40;

  final StageReport report;
  final LogicalDay today;

  @override
  Widget build(BuildContext context) {
    final byDay = {for (final day in report.daily) day.day: day};
    return MediaQuery.withNoTextScaling(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = math.min(_ring, constraints.maxWidth / _perRow);
          Widget ringFor(LogicalDay day) => StageDayRing(
            day: day,
            progress: day.isAfter(today) ? null : byDay[day],
            limit: report.stage.limit,
            isToday: day == today,
            size: size,
          );
          return Column(
            spacing: AppSpacing.xs,
            children: [
              for (var row = 0; row < report.days; row += _perRow)
                Row(
                  children: [
                    for (var i = row; i < row + _perRow; i++)
                      Expanded(
                        child: i < report.days
                            ? ringFor(report.stage.startDay.addDays(i))
                            : const SizedBox.shrink(),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

/// One day of the current stage. With no [progress] the day is still ahead.
class StageDayRing extends StatelessWidget {
  const StageDayRing({
    required this.day,
    required this.progress,
    required this.limit,
    required this.isToday,
    required this.size,
    super.key,
  });

  final LogicalDay day;
  final DailyProgress? progress;
  final int limit;
  final bool isToday;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final progress = this.progress;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      decoration: isToday
          ? BoxDecoration(
              color: context.exhale.inset,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            )
          : null,
      child: Column(
        spacing: 3,
        children: [
          SizedBox.square(
            dimension: size,
            child: CustomPaint(
              painter: StageRingPainter(
                fill: progress?.usedFraction ?? 0,
                strokeWidth: size / 11,
                color: progress == null
                    ? colors.primaryContainer
                    : _statusColor(context, progress.status),
                track: progress == null
                    ? colors.outlineVariant
                    : colors.surfaceContainerHigh,
                dashed: progress == null,
              ),
              child: Center(
                child: Text(
                  '${progress?.count ?? limit}',
                  style: text.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          Text(
            AppFormat.shortWeekday(day),
            style: text.labelSmall?.copyWith(
              color: isToday ? colors.onSurface : colors.onSurfaceVariant,
              fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// One dot per day, the start date above the first and the end date below.
class _DayDots extends StatelessWidget {
  const _DayDots({
    required this.report,
    required this.today,
    required this.semanticLabel,
  });

  final StageReport report;
  final LogicalDay today;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final small = context.textTheme.labelSmall?.copyWith(
      color: colors.onSurfaceVariant,
    );
    final byDay = {for (final day in report.daily) day.day: day};
    final dots = [
      for (var i = 0; i < report.days; i++)
        _dotFor(report.stage.startDay.addDays(i), byDay),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        Text(AppFormat.monthDay(report.stage.startDay), style: small),
        Semantics(
          container: true,
          image: true,
          label: semanticLabel,
          excludeSemantics: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final layout = DotLayout.of(
                days: report.days,
                width: constraints.maxWidth,
              );
              return SizedBox(
                height:
                    layout.rows * layout.size + (layout.rows - 1) * layout.gap,
                child: CustomPaint(
                  painter: DayDotsPainter(
                    dots: dots,
                    layout: layout,
                    under: colors.primaryContainer,
                    atLimit: context.exhale.warning.solid,
                    over: context.exhale.danger.solid,
                    ahead: colors.outlineVariant,
                  ),
                ),
              );
            },
          ),
        ),
        Row(
          spacing: AppSpacing.sm,
          children: [
            Expanded(
              child: Text(
                PlanCopy.eachDot,
                style: small?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Text(AppFormat.monthDay(report.lastDay), style: small),
          ],
        ),
      ],
    );
  }

  DayDot _dotFor(LogicalDay day, Map<LogicalDay, DailyProgress> byDay) {
    if (day == today) return DayDot.today;
    if (day.isAfter(today)) return DayDot.ahead;
    return switch (byDay[day]?.status) {
      LimitStatus.at => DayDot.atLimit,
      LimitStatus.over => DayDot.over,
      _ => DayDot.under,
    };
  }
}

class DayDotsPainter extends CustomPainter {
  const DayDotsPainter({
    required this.dots,
    required this.layout,
    required this.under,
    required this.atLimit,
    required this.over,
    required this.ahead,
  });

  final List<DayDot> dots;
  final DotGrid layout;
  final Color under;
  final Color atLimit;
  final Color over;
  final Color ahead;

  @override
  void paint(Canvas canvas, Size size) {
    final dot = layout.size;
    final across = layout.cols > 1
        ? (size.width - dot) / (layout.cols - 1)
        : 0.0;
    final todayStroke = math.max(2, (dot * 0.3).roundToDouble()).toDouble();
    final aheadStroke = dot < 8 ? 1.0 : 1.5;

    for (final (index, kind) in dots.indexed) {
      final center = Offset(
        index % layout.cols * across + dot / 2,
        index ~/ layout.cols * (dot + layout.gap) + dot / 2,
      );
      switch (kind) {
        case DayDot.under:
          canvas.drawCircle(center, dot / 2, Paint()..color = under);
        case DayDot.atLimit:
          canvas.drawCircle(center, dot / 2, Paint()..color = atLimit);
        case DayDot.over:
          canvas.drawCircle(center, dot / 2, Paint()..color = over);
        case DayDot.today:
          _ring(canvas, center, dot, todayStroke, under);
        case DayDot.ahead:
          _ring(canvas, center, dot, aheadStroke, ahead);
      }
    }
  }

  void _ring(
    Canvas canvas,
    Offset center,
    double dot,
    double stroke,
    Color color,
  ) => canvas.drawCircle(
    center,
    (dot - stroke) / 2,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = color,
  );

  @override
  bool shouldRepaint(DayDotsPainter old) =>
      old.layout != layout ||
      old.under != under ||
      old.atLimit != atLimit ||
      old.over != over ||
      old.ahead != ahead ||
      !_sameDots(old.dots);

  bool _sameDots(List<DayDot> other) {
    if (other.length != dots.length) return false;
    for (var i = 0; i < dots.length; i++) {
      if (other[i] != dots[i]) return false;
    }
    return true;
  }
}

class _Key extends StatelessWidget {
  const _Key();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      children: [
        _KeyEntry(PlanCopy.under, colors.primaryContainer),
        _KeyEntry(PlanCopy.atLimit, context.exhale.warning.solid),
        _KeyEntry(PlanCopy.over, context.exhale.danger.solid),
      ],
    );
  }
}

class _KeyEntry extends StatelessWidget {
  const _KeyEntry(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 6,
    children: [
      DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: const SizedBox.square(dimension: 8),
      ),
      Text(
        label,
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    ],
  );
}

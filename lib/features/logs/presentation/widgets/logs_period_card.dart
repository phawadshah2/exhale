import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/status_badge.dart';
import 'package:exhale/features/logs/presentation/providers/logs_providers.dart';
import 'package:exhale/features/tracking/domain/entities/period_range.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:exhale/features/tracking/domain/entities/trigger_breakdown.dart';
import 'package:exhale/features/tracking/presentation/trigger_ui.dart';
import 'package:flutter/material.dart';

/// The period's totals and every trigger as a filter chip.
class LogsPeriodCard extends StatelessWidget {
  const LogsPeriodCard({
    required this.view,
    required this.range,
    required this.today,
    required this.weekly,
    required this.trigger,
    required this.onPrevious,
    required this.onNext,
    required this.onTrigger,
    super.key,
  });

  final LogsView view;
  final PeriodRange range;
  final LogicalDay today;

  /// Whether the range is a calendar week that the arrows step through.
  final bool weekly;
  final Trigger? trigger;

  /// Null when [range] already starts at the earliest day Logs can show.
  final VoidCallback? onPrevious;

  /// Null when [range] already reaches today.
  final VoidCallback? onNext;
  final ValueChanged<Trigger?> onTrigger;

  bool get _current => !range.to.isBefore(today);

  String get _label {
    final dates = AppFormat.dayRange(range.from, range.to);
    return weekly && _current ? 'This week · $dates' : dates;
  }

  String get _scope => !weekly
      ? 'in this range'
      : _current
      ? 'this week · ${view.stats.allowedByToday} by today'
      : 'that week';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final stats = view.stats;
    final under = stats.underBy;
    final badge = under >= 0
        ? ('$under under', context.exhale.success)
        : ('${-under} over', context.exhale.danger);
    final showBadge = stats.allowedByToday > 0 || stats.logged > 0;
    final fill = stats.allowed == 0
        ? (stats.logged > 0 ? 1.0 : 0.0)
        : (stats.logged / stats.allowed).clamp(0.0, 1.0);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.gutterSm,
          children: [
            Row(
              children: [
                if (weekly)
                  IconButton(
                    tooltip: 'Previous week',
                    onPressed: onPrevious,
                    icon: const Icon(AppIcons.back, size: 18),
                  ),
                Expanded(
                  child: Text(
                    _label,
                    textAlign: TextAlign.center,
                    style: text.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (weekly)
                  IconButton(
                    tooltip: 'Next week',
                    onPressed: onNext,
                    icon: const Icon(AppIcons.chevronRight, size: 18),
                  ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${stats.logged}',
                              style: text.headlineSmall,
                            ),
                            TextSpan(
                              text: ' logged',
                              style: text.titleMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${stats.allowed} allowed $_scope',
                        style: text.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showBadge) StatusBadge(label: badge.$1, colors: badge.$2),
              ],
            ),
            ClipRRect(
              borderRadius: AppRadius.pill,
              child: LinearProgressIndicator(
                value: fill,
                minHeight: 8,
                backgroundColor: colors.surfaceContainerHighest,
                color: under < 0
                    ? context.exhale.danger.solid
                    : colors.primaryContainer,
              ),
            ),
            Divider(color: colors.outlineVariant.withValues(alpha: 0.4)),
            Text(
              'ALL TRIGGERS · TAP TO FILTER',
              style: text.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.9,
              ),
            ),
            _TriggerChips(
              breakdown: view.breakdown,
              selected: trigger,
              onSelect: onTrigger,
            ),
          ],
        ),
      ),
    );
  }
}

class _TriggerChips extends StatelessWidget {
  const _TriggerChips({
    required this.breakdown,
    required this.selected,
    required this.onSelect,
  });

  final TriggerBreakdown breakdown;
  final Trigger? selected;
  final ValueChanged<Trigger?> onSelect;

  static String _percent(double fraction) => '${(fraction * 100).round()}%';

  @override
  Widget build(BuildContext context) {
    if (breakdown.total == 0) {
      return Text(
        'Nothing logged in this period.',
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      );
    }
    final rank = [
      context.exhale.danger.foreground,
      context.colors.primary,
      context.exhale.warning.foreground,
    ];
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final (i, share) in breakdown.shares.indexed)
          _Chip(
            label:
                '${share.trigger.label} · ${share.count} · '
                '${_percent(share.fraction)}',
            color: i < rank.length ? rank[i] : null,
            selected: share.trigger == selected,
            onTap: () =>
                onSelect(share.trigger == selected ? null : share.trigger),
          ),
        if (breakdown.noTrigger > 0)
          _Chip(
            label:
                'No trigger · ${breakdown.noTrigger} · '
                '${_percent(breakdown.noTrigger / breakdown.total)}',
            muted: true,
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    this.color,
    this.selected = false,
    this.muted = false,
    this.onTap,
  });

  final String label;
  final Color? color;
  final bool selected;
  final bool muted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tint = color ?? colors.onSurface;
    return Semantics(
      button: onTap != null,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 32,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: ShapeDecoration(
            color: selected
                ? tint.withValues(alpha: 0.22)
                : color == null
                ? null
                : tint.withValues(alpha: 0.1),
            shape: StadiumBorder(
              side: BorderSide(
                color: color == null
                    ? colors.outlineVariant
                    : tint.withValues(alpha: selected ? 0.9 : 0.35),
              ),
            ),
          ),
          child: Text(
            label,
            style: context.textTheme.labelMedium?.copyWith(
              color: muted ? colors.onSurfaceVariant : tint,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

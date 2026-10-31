import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/section_card.dart';
import 'package:exhale/core/widgets/status_badge.dart';
import 'package:exhale/features/habit/presentation/habit_wording.dart';
import 'package:exhale/features/home/presentation/providers/home_providers.dart';
import 'package:flutter/material.dart';

/// Money summed across habits, the "All on track" streak, and what each
/// habit avoided: units are never added together.
class CombinedImpactCard extends StatelessWidget {
  const CombinedImpactCard({
    required this.impact,
    required this.currencySymbol,
    super.key,
  });

  final CombinedImpact impact;
  final String currencySymbol;

  _ImpactTile? _moneyTile(BuildContext context) {
    final costly = impact.habits.where((h) => h.tracked.habit.tracksCost);
    if (costly.isEmpty) return null;
    final priced = [
      for (final habit in costly)
        if (habit.stats.moneySavedCents case final double cents)
          (name: habit.tracked.habit.name, cents: cents),
    ];
    final total = priced.fold<double>(0, (sum, habit) => sum + habit.cents);
    return _ImpactTile(
      label: 'Money saved',
      value: priced.isEmpty
          ? '—'
          : AppFormat.money(total, symbol: currencySymbol),
      valueColor: priced.isEmpty ? null : context.exhale.success.foreground,
      caption: switch (priced.length) {
        0 => 'No price set',
        1 => '${priced.single.name}, since day 1',
        2 => 'Both habits, since day 1',
        final count => '$count habits, since day 1',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final streak = impact.streakDays;
    final money = _moneyTile(context);
    final tiles = [
      ?money,
      _ImpactTile(
        label: 'All on track',
        value: '$streak ${streak == 1 ? 'day' : 'days'}',
        caption: 'Every habit within limit',
      ),
      for (final habit in impact.habits)
        _ImpactTile(
          label: habit.tracked.habit.avoidedTitle,
          value: '${habit.stats.avoided}',
          caption: 'vs ${habit.stats.baseline}/day start',
        ),
    ];

    return SectionCard(
      title: 'Combined impact',
      trailing: streak > 0
          ? StatusBadge(
              label: 'Healthy trajectory',
              colors: context.exhale.success,
            )
          : null,
      child: Column(
        spacing: AppSpacing.gutterSm,
        children: [
          for (var row = 0; row < tiles.length; row += 2)
            if (row + 1 == tiles.length)
              SizedBox(width: double.infinity, child: tiles[row])
            else
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.gutterSm,
                  children: [
                    Expanded(child: tiles[row]),
                    Expanded(child: tiles[row + 1]),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _ImpactTile extends StatelessWidget {
  const _ImpactTile({
    required this.label,
    required this.value,
    required this.caption,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: AppRadius.inner,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Text(
            label,
            style: text.labelMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.headlineSmall?.copyWith(color: valueColor),
          ),
          Text(
            caption,
            style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

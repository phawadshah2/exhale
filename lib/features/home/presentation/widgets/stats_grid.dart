import 'dart:async';

import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/tracking/domain/entities/home_stats.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StatsGrid extends StatelessWidget {
  const StatsGrid({
    required this.habitId,
    required this.stats,
    required this.currencySymbol,
    required this.habit,
    super.key,
  });

  final int habitId;
  final HomeStats stats;
  final String currencySymbol;
  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final success = context.exhale.success.foreground;
    final danger = context.exhale.danger.foreground;
    final muted = context.colors.onSurfaceVariant;

    final change = stats.changeFromBaseline;
    final changeTile = change == null
        ? _StatTile(
            label: 'Vs baseline',
            icon: AppIcons.trendDown,
            iconColor: success,
            value: '—',
            caption: 'After your first full day',
            captionColor: muted,
          )
        : _StatTile(
            label: 'Vs baseline',
            icon: change <= 0 ? AppIcons.trendDown : AppIcons.trendUp,
            iconColor: change <= 0 ? success : danger,
            value:
                '${change <= 0 ? '↓' : '↑'} ${(change.abs() * 100).round()}%',
            valueColor: change <= 0 ? success : danger,
            caption: 'From ${stats.baseline}/day start',
            captionColor: muted,
          );

    final saved = stats.moneySavedCents;
    final tiles = [
      _StatTile(
        label: 'Streak',
        icon: AppIcons.flame,
        iconColor: context.exhale.warning.foreground,
        value: '${stats.streakDays} ${stats.streakDays == 1 ? 'Day' : 'Days'}',
        caption: 'within limit',
        captionColor: success,
      ),
      changeTile,
      if (habit.tracksCost)
        _StatTile(
          label: 'Money saved',
          icon: AppIcons.savings,
          iconColor: context.exhale.warning.foreground,
          value: saved == null
              ? '—'
              : AppFormat.money(saved, symbol: currencySymbol),
          caption: saved == null ? 'Add a price ›' : 'Since Day 1',
          captionColor: saved == null ? context.colors.primary : success,
          onTap: saved == null
              ? () => unawaited(context.push(AppRoutes.editPlanFor(habitId)))
              : null,
        ),
      _StatTile(
        label: 'Avoided',
        icon: AppIcons.avoided,
        iconColor: context.colors.primary,
        value:
            '${stats.avoided} '
            '${stats.avoided == 1 ? habit.unit : habit.shortUnits}',
        caption: 'vs ${stats.baseline}/day baseline',
        captionColor: muted,
      ),
    ];

    return Column(
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
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.caption,
    required this.captionColor,
    this.valueColor,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final String value;
  final Color? valueColor;
  final String caption;
  final Color captionColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: AppSpacing.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: text.labelMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Icon(icon, size: 20, color: iconColor),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                value,
                style: text.headlineMedium?.copyWith(color: valueColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                caption,
                style: text.bodySmall?.copyWith(color: captionColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

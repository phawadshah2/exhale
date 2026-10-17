import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// A short daily line of encouragement, rotating by plan day.
class QuoteCard extends StatelessWidget {
  const QuoteCard({required this.dayNumber, super.key});

  final int dayNumber;

  static const quotes = [
    'Every breath is a fresh decision.',
    'One fewer today is a real win.',
    'Cravings pass. You stay.',
    'Slow is still forward.',
    'Notice the urge, then let it go by.',
    'Each smaller day adds up.',
    'Progress, not perfection.',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: AppRadius.inner,
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        spacing: AppSpacing.gutterSm,
        children: [
          Icon(Symbols.spa, color: colors.primary),
          Expanded(
            child: Text(
              '"${quotes[(dayNumber - 1) % quotes.length]}"',
              style: context.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

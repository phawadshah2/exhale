import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/presence/domain/encouragement.dart';
import 'package:flutter/material.dart';

/// A short daily line of encouragement, rotating by plan day.
class QuoteCard extends StatelessWidget {
  const QuoteCard({required this.dayNumber, super.key});

  final int dayNumber;

  static final List<String> quotes = encouragementLines.take(7).toList();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: AppRadius.inner,
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        spacing: AppSpacing.gutterSm,
        children: [
          Icon(AppIcons.breath, color: colors.primary),
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

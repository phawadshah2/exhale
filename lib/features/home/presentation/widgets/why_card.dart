import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:flutter/material.dart';

/// The reason the user gave in setup, kept in sight.
class WhyCard extends StatelessWidget {
  const WhyCard({required this.reason, super.key});

  final String reason;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: AppSpacing.sm,
              children: [
                Icon(AppIcons.heart, size: 16, color: colors.primary),
                Text(
                  'YOUR WHY',
                  style: text.labelMedium?.copyWith(
                    color: colors.primary,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(reason, style: text.titleMedium),
          ],
        ),
      ),
    );
  }
}

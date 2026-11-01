import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/exhale_colors.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:flutter/material.dart';

/// Soft pill with a dot: "On track", "At limit", "Over limit".
class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.label, required this.colors, super.key});

  final String label;
  final StatusColors colors;

  @override
  Widget build(BuildContext context) {
    // Beside a title in a row; past this scale it would push the title out.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.5,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gutterSm,
          vertical: AppSpacing.xs,
        ),
        decoration: ShapeDecoration(
          color: colors.soft,
          shape: StadiumBorder(
            side: BorderSide(color: colors.foreground.withValues(alpha: 0.6)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: colors.foreground,
                shape: BoxShape.circle,
              ),
            ),
            Flexible(
              child: Text(
                label,
                style: context.textTheme.labelMedium?.copyWith(
                  color: colors.foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

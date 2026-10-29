import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:flutter/material.dart';

/// Thin segments filled up to the current step, a back chevron and a quiet
/// "n/total" count.
class OnboardingStepper extends StatelessWidget {
  const OnboardingStepper({
    required this.index,
    required this.total,
    this.onBack,
    super.key,
  });

  final int index;
  final int total;

  /// Null hides the chevron.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final exhale = context.exhale;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.gutterSm,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        children: [
          Row(
            spacing: 5,
            children: [
              for (var i = 0; i < total; i++)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 3,
                    decoration: BoxDecoration(
                      color: i <= index ? exhale.emphasis : exhale.inset,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(
            height: 44,
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: onBack == null
                      ? null
                      : IconButton(
                          tooltip: 'Back',
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                          onPressed: onBack,
                          icon: Icon(AppIcons.back, color: colors.onSurface),
                        ),
                ),
                Expanded(
                  child: Text(
                    '${index + 1}/$total',
                    textAlign: TextAlign.center,
                    style: context.textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 44),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

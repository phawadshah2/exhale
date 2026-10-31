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

  static const Duration _fill = Duration(milliseconds: 420);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = context.theme.brightness == Brightness.dark;
    // The mockup's track: a clear grey on both backgrounds.
    final track = isDark ? colors.surfaceContainerHigh : colors.surfaceDim;
    final still = MediaQuery.disableAnimationsOf(context);
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: SizedBox(
                      height: 3,
                      child: ColoredBox(
                        color: track,
                        // A segment fills left to right as its step opens and
                        // drains right to left on the way back.
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(end: i <= index ? 1 : 0),
                          duration: still ? Duration.zero : _fill,
                          curve: Curves.easeInOutCubic,
                          builder: (context, fill, _) => FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: fill,
                            child: ColoredBox(color: context.exhale.emphasis),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 36,
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

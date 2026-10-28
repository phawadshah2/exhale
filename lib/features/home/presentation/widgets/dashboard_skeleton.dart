import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:flutter/material.dart';

/// Placeholder cards that pulse while the dashboard's first data loads.
class DashboardSkeleton extends StatefulWidget {
  const DashboardSkeleton({super.key});

  @override
  State<DashboardSkeleton> createState() => _DashboardSkeletonState();
}

class _DashboardSkeletonState extends State<DashboardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    final colors = context.colors;
    Widget block(double height, {double radius = 24}) => Container(
      height: height,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
    return ExcludeSemantics(
      child: FadeTransition(
        opacity: Tween<double>(
          begin: 0.45,
          end: 1,
        ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: AppSpacing.page.copyWith(
            top: insets.top + AppSpacing.sm,
            bottom: insets.bottom + AppSpacing.lg,
          ),
          children: [
            Row(
              spacing: AppSpacing.gutterSm,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.surfaceContainerHigh,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      FractionallySizedBox(
                        widthFactor: 0.4,
                        child: block(12, radius: 6),
                      ),
                      FractionallySizedBox(
                        widthFactor: 0.7,
                        child: block(20, radius: 8),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            block(34, radius: 17),
            const SizedBox(height: AppSpacing.md),
            block(420),
            const SizedBox(height: AppSpacing.md),
            Row(
              spacing: AppSpacing.gutterSm,
              children: [
                Expanded(child: block(110, radius: 20)),
                Expanded(child: block(110, radius: 20)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            block(360),
          ],
        ),
      ),
    );
  }
}

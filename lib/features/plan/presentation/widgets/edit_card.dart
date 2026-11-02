import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:flutter/material.dart';

/// A card on Edit plan: a title with [side] on its right, wrapping under it
/// when they don't fit, then [children].
class EditCard extends StatelessWidget {
  const EditCard({
    required this.title,
    required this.children,
    this.side,
    super.key,
  });

  final String title;
  final Widget? side;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.gutterSm,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              children: [
                Text(title, style: context.textTheme.titleMedium),
                ?side,
              ],
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

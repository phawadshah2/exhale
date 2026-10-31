import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:flutter/material.dart';

/// A logs card's title with its "See all logs" link.
class LogsCardHeader extends StatelessWidget {
  const LogsCardHeader({
    required this.title,
    required this.onSeeAll,
    super.key,
  });

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
      child: Row(
        children: [
          Expanded(child: Text(title, style: text.titleLarge)),
          InkWell(
            onTap: onSeeAll,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Row(
                spacing: 4,
                children: [
                  Text(
                    'See all logs',
                    style: text.labelLarge?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(AppIcons.chevronRight, size: 14, color: colors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

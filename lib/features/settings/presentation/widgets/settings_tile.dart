import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/settings/domain/plan_tile_summary.dart';
import 'package:exhale/features/settings/presentation/widgets/settings_row.dart';
import 'package:flutter/material.dart';

/// A square Settings tile at the top of the page: icon, eyebrow, big value
/// and a small line. One button for VoiceOver.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    required this.icon,
    required this.summary,
    required this.onTap,
    this.accentIcon = false,
    super.key,
  });

  final IconData icon;
  final TileSummary summary;
  final VoidCallback onTap;
  final bool accentIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final line = summary.line;
    return Semantics(
      button: true,
      label: summary.semanticsLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SettingsIconTile(icon: icon, filled: accentIcon),
                const SizedBox(height: AppSpacing.gutterSm),
                Text(
                  summary.eyebrow,
                  style: text.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                Text(summary.value, style: text.titleLarge),
                if (line != null)
                  Text(
                    line,
                    style: text.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

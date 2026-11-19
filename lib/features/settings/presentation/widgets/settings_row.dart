import 'dart:async';

import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One Settings row: an icon in a soft tile, a label, then a value and
/// chevron (when [onTap] is set), a switch (when [onSwitch] is set) or
/// [trailing].
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
    this.switchValue,
    this.onSwitch,
    this.trailing,
    super.key,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  final bool? switchValue;
  final ValueChanged<bool>? onSwitch;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final onSwitch = this.onSwitch;
    final value = this.value;
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          spacing: AppSpacing.gutterSm,
          children: [
            SettingsIconTile(icon: icon),
            Expanded(child: Text(label, style: text.bodyLarge)),
            if (value != null)
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: text.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ?trailing,
            if (onSwitch != null)
              CupertinoSwitch(
                value: switchValue ?? false,
                activeTrackColor: colors.primary,
                onChanged: (on) {
                  unawaited(HapticFeedback.selectionClick());
                  onSwitch(on);
                },
              )
            else if (onTap != null)
              Icon(
                AppIcons.chevronRight,
                size: 16,
                color: colors.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
    if (onSwitch != null) {
      return MergeSemantics(
        child: Semantics(toggled: switchValue ?? false, child: row),
      );
    }
    if (onTap == null) return row;
    return Semantics(
      button: true,
      child: InkWell(onTap: onTap, child: row),
    );
  }
}

/// A 28 pt soft square holding a row's icon.
class SettingsIconTile extends StatelessWidget {
  const SettingsIconTile({required this.icon, this.filled = false, super.key});

  final IconData icon;

  /// Accent-filled, for the plan tile.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ExcludeSemantics(
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: filled ? colors.primary : context.exhale.inset,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(
          icon,
          size: 16,
          color: filled ? colors.onPrimary : colors.onSurface,
        ),
      ),
    );
  }
}

/// Rows in one card, with an optional small header above it.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({required this.rows, this.header, super.key});

  final String? header;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final header = this.header;
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              0,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Semantics(
              header: true,
              child: Text(
                header.toUpperCase(),
                style: context.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (i, row) in rows.indexed) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: AppSpacing.md + 28 + AppSpacing.gutterSm,
                    color: colors.outlineVariant,
                  ),
                row,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

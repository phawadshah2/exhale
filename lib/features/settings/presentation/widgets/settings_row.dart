import 'dart:async';

import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One Settings row: an optional icon in a soft tile, a label, then a value
/// and chevron (when [onTap] is set), a switch (when [onSwitch] is set) or
/// [trailing]. A row that is not [enabled] is dimmed and ignores taps.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.label,
    this.icon,
    this.value,
    this.onTap,
    this.switchValue,
    this.onSwitch,
    this.trailing,
    this.enabled = true,
    this.chevron = true,
    super.key,
  });

  final IconData? icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  final bool? switchValue;
  final ValueChanged<bool>? onSwitch;
  final Widget? trailing;
  final bool enabled;

  /// False for a row that acts in place (Restore) rather than opening
  /// something.
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final icon = this.icon;
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
            if (icon != null) SettingsIconTile(icon: icon),
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
            else if (onTap != null && chevron)
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
    if (!enabled) {
      return Semantics(
        button: true,
        enabled: false,
        child: Opacity(opacity: 0.45, child: row),
      );
    }
    return Semantics(
      button: true,
      enabled: true,
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

/// Rows in one card, with an optional small header above it. Dividers
/// start past the icon unless the rows have none ([iconRows] false).
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    required this.rows,
    this.header,
    this.iconRows = true,
    super.key,
  });

  final String? header;
  final List<Widget> rows;
  final bool iconRows;

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
                    indent: iconRows
                        ? AppSpacing.md + 28 + AppSpacing.gutterSm
                        : AppSpacing.md,
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

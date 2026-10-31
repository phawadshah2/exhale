import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:flutter/material.dart';

/// The round 44 pt button in a page's back bar.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.accent = false,
    super.key,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tint = accent ? colors.primary : colors.onSurface;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: GestureDetector(
          onTap: onPressed,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent
                  ? colors.primary.withValues(alpha: 0.14)
                  : colors.surfaceContainerHigh,
              border: Border.all(
                color: accent
                    ? colors.primary.withValues(alpha: 0.45)
                    : colors.outlineVariant,
              ),
            ),
            child: Icon(icon, size: 20, color: tint),
          ),
        ),
      ),
    );
  }
}

import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:flutter/material.dart';

/// A round outlined − / + button; dimmed and inert while [onTap] is null.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.size = 48,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.4,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color:
                  context.theme.cardTheme.color ?? colors.surfaceContainerLow,
              shape: BoxShape.circle,
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Icon(icon, size: size * 0.42, color: colors.onSurface),
          ),
        ),
      ),
    );
  }
}

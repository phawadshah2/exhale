import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:flutter/material.dart';

/// Primary pill button with the accent halo ("Log a smoke", "Start my plan").
class GlowButton extends StatelessWidget {
  const GlowButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isBusy = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isBusy;
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        shadows: enabled ? context.exhale.accentGlow : null,
      ),
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        child: isBusy
            ? SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: context.colors.onPrimaryContainer,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 10,
                children: [
                  if (icon != null) Icon(icon),
                  Text(label),
                  if (trailingIcon != null) Icon(trailingIcon),
                ],
              ),
      ),
    );
  }
}

import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:flutter/material.dart';

/// Primary pill button.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
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
    return FilledButton(
      onPressed: enabled ? onPressed : null,
      child: isBusy
          ? SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: context.exhale.onEmphasis,
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
    );
  }
}

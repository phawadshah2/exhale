import 'dart:math' as math;

import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/glow_button.dart';
import 'package:exhale/core/widgets/scroll_edge_blur.dart';
import 'package:flutter/material.dart';

/// Room the floating footer takes above the bottom inset.
const double setupFooterHeight = 96;

/// Edge-to-edge scrolling form with a footer the keyboard slides over.
/// Tapping outside a field or scrolling closes the keyboard.
class SetupScaffold extends StatelessWidget {
  const SetupScaffold({
    required this.children,
    required this.footer,
    super.key,
  });

  final List<Widget> children;
  final Widget Function(double bottomInset) footer;

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: ScrollEdgeBlur(
        child: Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: AppSpacing.page.copyWith(
                  top: insets.top + AppSpacing.md,
                  bottom: math.max(
                    keyboard + AppSpacing.lg,
                    insets.bottom + setupFooterHeight + AppSpacing.lg,
                  ),
                ),
                children: children,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: footer(insets.bottom),
            ),
          ],
        ),
      ),
    );
  }
}

class SetupStepChip extends StatelessWidget {
  const SetupStepChip({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: ShapeDecoration(
        color: colors.surfaceContainerHigh,
        shape: StadiumBorder(
          side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
          ),
          Text(label, style: context.textTheme.labelLarge),
        ],
      ),
    );
  }
}

/// Primary button floating over the form, with only a soft fade behind it.
class SetupFooter extends StatelessWidget {
  const SetupFooter({
    required this.label,
    required this.bottomInset,
    required this.onPressed,
    this.isBusy = false,
    this.caption = 'You can adjust your plan anytime in Settings.',
    super.key,
  });

  final String label;
  final String caption;
  final double bottomInset;
  final bool isBusy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors.surface.withValues(alpha: 0),
            colors.surface.withValues(alpha: 0.85),
            colors.surface,
          ],
          stops: const [0, 0.45, 1],
        ),
      ),
      child: Padding(
        padding: AppSpacing.page.copyWith(
          top: AppSpacing.xl,
          bottom: bottomInset + AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlowButton(
              label: label,
              trailingIcon: AppIcons.forward,
              isBusy: isBusy,
              onPressed: onPressed,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 6,
              children: [
                Icon(AppIcons.tune, size: 16, color: colors.onSurfaceVariant),
                Flexible(
                  child: Text(
                    caption,
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

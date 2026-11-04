import 'dart:math' as math;

import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/primary_button.dart';
import 'package:exhale/core/widgets/scroll_reveal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Edge-to-edge scrolling form with a footer the keyboard slides over.
/// Tapping outside a field or scrolling closes the keyboard.
class SetupScaffold extends StatefulWidget {
  const SetupScaffold({
    required this.children,
    required this.footer,
    super.key,
  });

  final List<Widget> children;
  final Widget Function(double bottomInset) footer;

  @override
  State<SetupScaffold> createState() => _SetupScaffoldState();
}

class _SetupScaffoldState extends State<SetupScaffold> {
  /// The footer as last laid out; it grows with its caption and with text
  /// size, and the form has to scroll clear of all of it.
  double _footerHeight = 0;

  void _footerResized(Size size) {
    if (mounted) setState(() => _footerHeight = size.height);
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            excludeFromSemantics: true,
            onTap: () => FocusScope.of(context).unfocus(),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: AppSpacing.page.copyWith(
                top: insets.top + AppSpacing.md,
                bottom: math.max(keyboard + AppSpacing.lg, _footerHeight),
              ),
              children: [
                for (final (i, child) in widget.children.indexed)
                  ScrollReveal(index: i, child: child),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _SizeReporter(
              onResized: _footerResized,
              child: widget.footer(insets.bottom),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reports its child's size after a frame that changed it.
class _SizeReporter extends SingleChildRenderObjectWidget {
  const _SizeReporter({required this.onResized, required super.child});

  final ValueChanged<Size> onResized;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSizeReporter(onResized);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSizeReporter renderObject,
  ) => renderObject.onResized = onResized;
}

class _RenderSizeReporter extends RenderProxyBox {
  _RenderSizeReporter(this.onResized);

  ValueChanged<Size> onResized;
  Size? _reported;

  @override
  void performLayout() {
    super.performLayout();
    final current = size;
    if (current == _reported) return;
    _reported = current;
    WidgetsBinding.instance.addPostFrameCallback((_) => onResized(current));
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
    this.caption,
    this.isBusy = false,
    super.key,
  });

  final String label;
  final String? caption;
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
            colors.surface,
            colors.surface,
          ],
          stops: const [0, 0.3, 1],
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
            PrimaryButton(label: label, isBusy: isBusy, onPressed: onPressed),
            if (caption case final caption?) ...[
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
          ],
        ),
      ),
    );
  }
}

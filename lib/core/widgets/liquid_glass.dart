import 'dart:async';

import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/glass_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

List<BoxShadow> _floatingShadow(bool isDark) => [
  BoxShadow(
    color: Colors.black.withValues(alpha: isDark ? 0.36 : 0.14),
    blurRadius: 24,
    spreadRadius: -6,
    offset: const Offset(0, 8),
  ),
];

/// Shares one backdrop sample between the [AppGlass] shapes below it.
/// Without glass (Reduce Transparency) it is a no-op.
class AppGlassLayer extends StatelessWidget {
  const AppGlassLayer({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!GlassMode.of(context)) return child;
    final brightness = Theme.of(context).brightness;
    return LiquidGlassLayer(
      settings: LiquidGlassSettings.ios27Regular(brightness: brightness),
      defaultAppearance: LiquidGlassAppearance.ios27Regular(
        brightness: brightness,
      ),
      child: child,
    );
  }
}

/// A floating control in Liquid Glass (refracting, iOS 26 style), or a
/// solid surface when Reduce Transparency is on.
///
/// [radius] null gives a circle/oval. [tint] colours the glass (accent
/// buttons). Renders on a parent [AppGlassLayer] when there is one.
class AppGlass extends StatelessWidget {
  const AppGlass({
    required this.child,
    this.radius,
    this.tint,
    this.frosted = false,
    super.key,
  });

  final Widget child;
  final double? radius;
  final Color? tint;

  /// Apple's "tinted" glass: more frost behind content-heavy surfaces such
  /// as sheets, so text stays readable.
  final bool frosted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = colors.brightness == Brightness.dark;
    final radius = this.radius;
    final tint = this.tint;

    if (!GlassMode.of(context)) {
      final ShapeBorder shape = radius == null
          ? const CircleBorder()
          : RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(radius),
            );
      return DecoratedBox(
        decoration: ShapeDecoration(
          shape: shape,
          color:
              tint ??
              (isDark
                  ? colors.surfaceContainerHigh
                  : colors.surfaceContainerLowest),
          shadows: _floatingShadow(isDark),
        ),
        child: child,
      );
    }

    final brightness = Theme.of(context).brightness;
    return LiquidGlass.auto(
      shape: radius == null
          ? const LiquidOval()
          : LiquidRoundedSuperellipse(borderRadius: radius),
      settings: LiquidGlassSettings.ios27Regular(
        brightness: brightness,
        tintAmount: frosted ? 1 : 0,
      ),
      appearance: tint == null
          ? null
          : LiquidGlassAppearance.ios27Regular(
              brightness: brightness,
              tint: tint.withValues(alpha: 0.6),
            ),
      shadows: _floatingShadow(isDark),
      child: child,
    );
  }
}

/// Round glass icon button, as in iOS 26 sheet and toolbar controls.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 40,
    this.tint,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double size;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: AppGlass(
            tint: tint,
            child: SizedBox.square(
              dimension: size,
              child: Icon(
                icon,
                size: size * 0.45,
                color: tint == null
                    ? colors.onSurface
                    : colors.onPrimaryContainer,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

@immutable
class GlassMenuItem {
  const GlassMenuItem({
    required this.label,
    required this.icon,
    required this.onSelected,
  });

  final String label;
  final IconData icon;
  final VoidCallback onSelected;
}

/// iOS pull-down menu in glass, growing from [anchor] (a global rect).
Future<void> showGlassMenu(
  BuildContext context, {
  required Rect anchor,
  required List<GlassMenuItem> items,
}) async {
  unawaited(HapticFeedback.mediumImpact());
  final selected = await Navigator.of(
    context,
    rootNavigator: true,
  ).push<GlassMenuItem>(_GlassMenuRoute(anchor: anchor, items: items));
  selected?.onSelected();
}

class _GlassMenuRoute extends PopupRoute<GlassMenuItem> {
  _GlassMenuRoute({required this.anchor, required this.items});

  final Rect anchor;
  final List<GlassMenuItem> items;

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Close menu';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 280);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 160);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final size = MediaQuery.sizeOf(context);
    final colors = context.colors;
    final text = context.textTheme;
    final growth = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );
    return Stack(
      children: [
        Positioned(
          right: size.width - anchor.right,
          bottom: size.height - anchor.top + 10,
          child: FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.6, end: 1).animate(growth),
              alignment: Alignment.bottomRight,
              child: AppGlass(
                radius: 26,
                child: Material(
                  type: MaterialType.transparency,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 230),
                    child: IntrinsicWidth(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final item in items)
                              InkWell(
                                onTap: () => Navigator.of(context).pop(item),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 13,
                                  ),
                                  child: Row(
                                    spacing: 14,
                                    children: [
                                      Icon(
                                        item.icon,
                                        size: 20,
                                        color: colors.primary,
                                      ),
                                      Text(item.label, style: text.bodyLarge),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

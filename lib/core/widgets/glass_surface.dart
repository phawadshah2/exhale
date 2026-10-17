import 'dart:ui';

import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:flutter/material.dart';

/// Whether translucent, blurred surfaces are on. Provided above the
/// navigator in app.dart so routes (sheets, dialogs) see it too.
class GlassMode extends InheritedWidget {
  const GlassMode({required this.enabled, required super.child, super.key});

  final bool enabled;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GlassMode>()?.enabled ?? true;

  @override
  bool updateShouldNotify(GlassMode oldWidget) => enabled != oldWidget.enabled;
}

/// iOS-style material: blurred and translucent with a hairline edge, or a
/// solid surface when glass effects are off.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    required this.child,
    this.radius,
    this.blur = 24,
    this.color,
    this.shadow = true,
    super.key,
  });

  final Widget child;

  /// Corner radius; null gives a capsule.
  final double? radius;
  final double blur;

  /// Base colour before translucency; defaults to an elevated surface.
  final Color? color;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = colors.brightness == Brightness.dark;
    final glass = GlassMode.of(context);

    final hairline = BorderSide(
      color: isDark
          ? Colors.white.withValues(alpha: 0.09)
          : Colors.black.withValues(alpha: 0.07),
      width: 0.6,
    );
    final ShapeBorder shape = radius == null
        ? StadiumBorder(side: hairline)
        : RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius!),
            side: hairline,
          );

    final base =
        color ??
        (isDark ? colors.surfaceContainerHigh : colors.surfaceContainerLowest);
    final fill = glass ? base.withValues(alpha: isDark ? 0.62 : 0.72) : base;

    Widget surface = DecoratedBox(
      decoration: ShapeDecoration(color: fill, shape: shape),
      child: child,
    );
    if (glass) {
      surface = ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: surface,
        ),
      );
    }

    if (!shadow) return surface;
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.12),
            blurRadius: 28,
            spreadRadius: -8,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: surface,
    );
  }
}

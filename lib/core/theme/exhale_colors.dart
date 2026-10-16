import 'package:flutter/material.dart';

/// One status colour family (success, warning or danger).
@immutable
class StatusColors {
  const StatusColors({
    required this.solid,
    required this.onSolid,
    required this.foreground,
  });

  factory StatusColors.lerp(StatusColors a, StatusColors b, double t) =>
      StatusColors(
        solid: Color.lerp(a.solid, b.solid, t)!,
        onSolid: Color.lerp(a.onSolid, b.onSolid, t)!,
        foreground: Color.lerp(a.foreground, b.foreground, t)!,
      );

  /// Fills: chart bars, ring strokes, solid badges.
  final Color solid;

  /// Text and icons placed on [solid].
  final Color onSolid;

  /// Text and icons drawn straight on a surface ("On track", "2 over").
  final Color foreground;

  /// Tinted background for soft badges and chips.
  Color get soft => solid.withValues(alpha: 0.16);
}

/// App-specific colours that [ColorScheme] has no good name for.
///
/// Read it with `context.exhale` (see theme_context_extension.dart).
@immutable
class ExhaleColors extends ThemeExtension<ExhaleColors> {
  const ExhaleColors({
    required this.success,
    required this.warning,
    required this.danger,
    required this.glow,
  });

  /// Derived from the scheme so there is a single source of truth.
  factory ExhaleColors.fromScheme(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    return ExhaleColors(
      success: StatusColors(
        solid: scheme.secondaryContainer,
        onSolid: scheme.onSecondaryContainer,
        foreground: scheme.secondary,
      ),
      warning: StatusColors(
        solid: scheme.tertiaryContainer,
        onSolid: scheme.onTertiaryContainer,
        foreground: scheme.tertiary,
      ),
      danger: StatusColors(
        solid: scheme.errorContainer,
        onSolid: scheme.onErrorContainer,
        foreground: scheme.error,
      ),
      glow: scheme.primaryContainer.withValues(alpha: isDark ? 0.28 : 0.35),
    );
  }

  /// Under limit, streaks, milestones reached.
  final StatusColors success;

  /// Exactly at the daily limit.
  final StatusColors warning;

  /// Over the daily limit.
  final StatusColors danger;

  /// Soft accent halo around the primary log button and active ring.
  final Color glow;

  List<BoxShadow> get accentGlow => [
    BoxShadow(color: glow, blurRadius: 24, spreadRadius: -2),
  ];

  @override
  ExhaleColors copyWith({
    StatusColors? success,
    StatusColors? warning,
    StatusColors? danger,
    Color? glow,
  }) => ExhaleColors(
    success: success ?? this.success,
    warning: warning ?? this.warning,
    danger: danger ?? this.danger,
    glow: glow ?? this.glow,
  );

  // Called by AnimatedTheme while switching light <-> dark, so colours
  // fade instead of jumping.
  @override
  ExhaleColors lerp(ExhaleColors? other, double t) {
    if (other == null) return this;
    return ExhaleColors(
      success: StatusColors.lerp(success, other.success, t),
      warning: StatusColors.lerp(warning, other.warning, t),
      danger: StatusColors.lerp(danger, other.danger, t),
      glow: Color.lerp(glow, other.glow, t)!,
    );
  }
}

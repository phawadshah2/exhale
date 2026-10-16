import 'package:flutter/material.dart';

abstract final class AppFonts {
  /// Headlines, counters and display numbers.
  static const String display = 'Manrope';

  /// Titles, body copy and labels.
  static const String body = 'PlusJakartaSans';
}

/// The Stitch type scale mapped onto Material's [TextTheme] slots.
///
/// Colours are left out on purpose. AppTheme applies them per brightness.
abstract final class AppTypography {
  static const _tabular = [FontFeature.tabularFigures()];

  static TextStyle _style({
    required String family,
    required double size,
    required double lineHeight,
    required FontWeight weight,
    double letterSpacingEm = 0,
    bool tabular = false,
  }) => TextStyle(
    fontFamily: family,
    fontSize: size,
    height: lineHeight / size,
    fontWeight: weight,
    // DESIGN.md gives tracking in em; Flutter wants logical pixels.
    letterSpacing: size * letterSpacingEm,
    leadingDistribution: TextLeadingDistribution.even,
    fontFeatures: tabular ? _tabular : null,
  );

  static final TextTheme textTheme = TextTheme(
    // display-lg: hero numbers (ring counter).
    displayLarge: _style(
      family: AppFonts.display,
      size: 48,
      lineHeight: 56,
      weight: FontWeight.w700,
      letterSpacingEm: -0.03,
      tabular: true,
    ),
    // display-lg-mobile.
    displayMedium: _style(
      family: AppFonts.display,
      size: 36,
      lineHeight: 44,
      weight: FontWeight.w700,
      letterSpacingEm: -0.02,
      tabular: true,
    ),
    displaySmall: _style(
      family: AppFonts.display,
      size: 32,
      lineHeight: 40,
      weight: FontWeight.w700,
      letterSpacingEm: -0.02,
      tabular: true,
    ),
    headlineLarge: _style(
      family: AppFonts.display,
      size: 32,
      lineHeight: 40,
      weight: FontWeight.w600,
      letterSpacingEm: -0.02,
    ),
    headlineMedium: _style(
      family: AppFonts.display,
      size: 24,
      lineHeight: 32,
      weight: FontWeight.w600,
      letterSpacingEm: -0.01,
    ),
    headlineSmall: _style(
      family: AppFonts.display,
      size: 20,
      lineHeight: 28,
      weight: FontWeight.w600,
    ),
    titleLarge: _style(
      family: AppFonts.display,
      size: 18,
      lineHeight: 26,
      weight: FontWeight.w600,
    ),
    titleMedium: _style(
      family: AppFonts.body,
      size: 16,
      lineHeight: 24,
      weight: FontWeight.w600,
    ),
    titleSmall: _style(
      family: AppFonts.body,
      size: 14,
      lineHeight: 20,
      weight: FontWeight.w600,
    ),
    bodyLarge: _style(
      family: AppFonts.body,
      size: 16,
      lineHeight: 24,
      weight: FontWeight.w400,
    ),
    bodyMedium: _style(
      family: AppFonts.body,
      size: 14,
      lineHeight: 20,
      weight: FontWeight.w400,
    ),
    bodySmall: _style(
      family: AppFonts.body,
      size: 12,
      lineHeight: 18,
      weight: FontWeight.w400,
    ),
    labelLarge: _style(
      family: AppFonts.body,
      size: 14,
      lineHeight: 20,
      weight: FontWeight.w600,
      letterSpacingEm: 0.01,
    ),
    labelMedium: _style(
      family: AppFonts.body,
      size: 12,
      lineHeight: 16,
      weight: FontWeight.w500,
      letterSpacingEm: 0.02,
    ),
    labelSmall: _style(
      family: AppFonts.body,
      size: 10,
      lineHeight: 14,
      weight: FontWeight.w600,
      letterSpacingEm: 0.04,
    ),
  );
}

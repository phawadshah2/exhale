import 'package:exhale/core/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// Builds the Material [ColorScheme] for one brightness and accent.
///
/// Accent roles come from the seed algorithm, so any accent swatch works.
/// Secondary = success (emerald), tertiary = warning (amber),
/// error = danger (coral), and surfaces come from the hand-picked ramp.
ColorScheme buildColorScheme({
  required Brightness brightness,
  Color accent = AppPalette.eucalyptus,
}) {
  ColorScheme seeded(Color seed) => ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
    // `fidelity` keeps the seed as the *Container colour whenever its tone
    // allows (eucalyptus, emerald, amber stay exact). Coral and some
    // accents get nudged slightly brighter to keep contrast.
    dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
  );

  final base = seeded(accent);
  final success = seeded(AppPalette.emerald);
  final warning = seeded(AppPalette.amber);
  final danger = seeded(AppPalette.coral);
  final neutrals = brightness == Brightness.dark
      ? AppPalette.darkNeutrals
      : AppPalette.lightNeutrals;

  return base.copyWith(
    secondary: success.primary,
    onSecondary: success.onPrimary,
    secondaryContainer: success.primaryContainer,
    onSecondaryContainer: success.onPrimaryContainer,
    tertiary: warning.primary,
    onTertiary: warning.onPrimary,
    tertiaryContainer: warning.primaryContainer,
    onTertiaryContainer: warning.onPrimaryContainer,
    error: danger.primary,
    onError: danger.onPrimary,
    errorContainer: danger.primaryContainer,
    onErrorContainer: danger.onPrimaryContainer,
    surface: neutrals.surface,
    surfaceDim: neutrals.surfaceDim,
    surfaceBright: neutrals.surfaceBright,
    surfaceContainerLowest: neutrals.containerLowest,
    surfaceContainerLow: neutrals.containerLow,
    surfaceContainer: neutrals.container,
    surfaceContainerHigh: neutrals.containerHigh,
    surfaceContainerHighest: neutrals.containerHighest,
    onSurface: neutrals.onSurface,
    outlineVariant: neutrals.hairline,
    inverseSurface: neutrals.inverseSurface,
    onInverseSurface: neutrals.onInverseSurface,
  );
}

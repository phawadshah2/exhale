import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Raw brand values from the Stitch "Obsidian Sanctuary" design system
/// (design/obsidian_sanctuary/DESIGN.md).
///
/// Widgets never read these directly. They go through `ColorScheme` and
/// `ExhaleColors`, so light/dark and accent changes happen in one place.
abstract final class AppPalette {
  // Seeds for ColorScheme.fromSeed(variant: fidelity). Eucalyptus and
  // emerald reproduce Stitch's dark primary / secondary roles exactly.
  static const Color eucalyptus = Color(0xFF2DD4BF);
  static const Color emerald = Color(0xFF10B981);
  static const Color amber = Color(0xFFF59E0B);
  static const Color coral = Color(0xFFEF4444);

  static const Color ocean = Color(0xFF3B82F6);

  /// Accent choices offered in Settings > Appearance, by stored index.
  static const List<AccentSwatch> accents = [
    AccentSwatch(name: 'Eucalyptus', color: eucalyptus),
    AccentSwatch(name: 'Ocean', color: ocean),
  ];

  /// The accent for a stored index; unknown indexes fall back to the first.
  static AccentSwatch accentAt(int index) =>
      index >= 0 && index < accents.length ? accents[index] : accents.first;

  /// Stitch's blue-slate surfaces. These are hand-picked, not seed-derived,
  /// so they are listed explicitly.
  static const NeutralRamp darkNeutrals = NeutralRamp(
    surface: Color(0xFF0E141D),
    surfaceDim: Color(0xFF0E141D),
    surfaceBright: Color(0xFF343944),
    containerLowest: Color(0xFF080E17),
    containerLow: Color(0xFF161C25),
    container: Color(0xFF1A2029),
    containerHigh: Color(0xFF242A34),
    containerHighest: Color(0xFF2F353F),
    onSurface: Color(0xFFDDE2F0),
    hairline: Color(0xFF2C333D),
    inverseSurface: Color(0xFFDDE2F0),
    onInverseSurface: Color(0xFF2B313B),
  );

  /// Light mode was not designed in Stitch: a soft, airy cool slate.
  /// Containers stay close to white so cards read clean, not grey.
  static const NeutralRamp lightNeutrals = NeutralRamp(
    surface: Color(0xFFF4F7FA),
    surfaceDim: Color(0xFFD8DEE6),
    surfaceBright: Color(0xFFF4F7FA),
    containerLowest: Color(0xFFFFFFFF),
    containerLow: Color(0xFFF4F6F9),
    container: Color(0xFFF1F4F7),
    containerHigh: Color(0xFFECF0F4),
    containerHighest: Color(0xFFE6EBF0),
    onSurface: Color(0xFF161C25),
    hairline: Color(0xFFE4E9EF),
    inverseSurface: Color(0xFF2B313B),
    onInverseSurface: Color(0xFFEDF1F7),
  );
}

@immutable
class AccentSwatch {
  const AccentSwatch({required this.name, required this.color});

  final String name;
  final Color color;
}

@immutable
class NeutralRamp {
  const NeutralRamp({
    required this.surface,
    required this.surfaceDim,
    required this.surfaceBright,
    required this.containerLowest,
    required this.containerLow,
    required this.container,
    required this.containerHigh,
    required this.containerHighest,
    required this.onSurface,
    required this.hairline,
    required this.inverseSurface,
    required this.onInverseSurface,
  });

  final Color surface;
  final Color surfaceDim;
  final Color surfaceBright;
  final Color containerLowest;
  final Color containerLow;
  final Color container;
  final Color containerHigh;
  final Color containerHighest;
  final Color onSurface;

  /// Borders and dividers (outlineVariant); kept faint for a clean look.
  final Color hairline;
  final Color inverseSurface;
  final Color onInverseSurface;
}

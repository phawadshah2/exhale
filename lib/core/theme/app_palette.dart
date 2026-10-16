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

  /// Accent choices offered in Settings > Appearance.
  static const List<Color> accents = [
    eucalyptus,
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    emerald,
    amber,
  ];

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
    inverseSurface: Color(0xFFDDE2F0),
    onInverseSurface: Color(0xFF2B313B),
  );

  /// Light mode was not designed in Stitch. This mirrors the dark ramp in
  /// the same cool slate hue so both modes feel like one product.
  static const NeutralRamp lightNeutrals = NeutralRamp(
    surface: Color(0xFFF4F7FA),
    surfaceDim: Color(0xFFD8DEE6),
    surfaceBright: Color(0xFFF4F7FA),
    containerLowest: Color(0xFFFFFFFF),
    containerLow: Color(0xFFEEF2F6),
    container: Color(0xFFE8EDF2),
    containerHigh: Color(0xFFE2E8EE),
    containerHighest: Color(0xFFDBE2E9),
    onSurface: Color(0xFF161C25),
    inverseSurface: Color(0xFF2B313B),
    onInverseSurface: Color(0xFFEDF1F7),
  );
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
  final Color inverseSurface;
  final Color onInverseSurface;
}

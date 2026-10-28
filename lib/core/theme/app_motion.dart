import 'package:flutter/animation.dart';

/// Shared timings, so rings, bars, charts and cards all move at one speed.
abstract final class AppMotion {
  /// Rings, bars and charts filling from empty.
  static const Duration fill = Duration(milliseconds: 1600);

  /// A short hold first, so a swipe or a toggle settles before data moves.
  static const Curve fillCurve = Interval(
    0.15,
    1,
    curve: Curves.easeInOutCubic,
  );

  /// Content fading and resizing in or out.
  static const Duration swap = Duration(milliseconds: 500);
  static const Curve swapCurve = Curves.easeInOutCubic;

  /// Cards appearing as they scroll into view.
  static const Duration reveal = Duration(milliseconds: 700);
}

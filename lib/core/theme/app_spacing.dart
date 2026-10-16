import 'package:flutter/widgets.dart';

/// 8pt spacing scale from DESIGN.md.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double gutterSm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  /// Horizontal page margin.
  static const double pageMargin = 20;

  static const EdgeInsets page = EdgeInsets.symmetric(horizontal: pageMargin);
  static const EdgeInsets card = EdgeInsets.all(md);
}

abstract final class AppRadius {
  /// Small badges and swatches.
  static const double sm = 8;

  /// Elements nested inside cards.
  static const double md = 16;

  /// Cards and bottom sheets.
  static const double lg = 24;

  static const BorderRadius card = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius inner = BorderRadius.all(Radius.circular(md));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));
}

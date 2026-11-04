import 'dart:math' as math;

typedef DotGrid = ({int cols, int rows, double size, double gap});

/// How a current stage over 14 days lays out its dots: 13 across up to 4 rows,
/// then 4 rows with more across and smaller dots, down to 7 px at 33 across.
/// Past that the dots stay at 7 px and the rows grow.
abstract final class DotLayout {
  static const int _baseCols = 13;
  static const int _baseDays = 52;
  static const int _maxCols = 33;
  static const int _rows = 4;

  static DotGrid of({required int days, required double width}) {
    final cols = days <= _baseDays
        ? _baseCols
        : math.min(_maxCols, (days / _rows).ceil());
    final size = (width / cols * 0.72).floorToDouble().clamp(7.0, 16.0);
    return (
      cols: cols,
      rows: (days / cols).ceil(),
      size: size,
      gap: (size * 0.5).roundToDouble().clamp(3.0, 8.0),
    );
  }
}

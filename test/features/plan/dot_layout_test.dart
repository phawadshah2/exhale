import 'package:exhale/features/plan/presentation/dot_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const width = 322.0;

  for (final (days, cols, rows, size) in const [
    (15, 13, 2, 16.0),
    (52, 13, 4, 16.0),
    (53, 14, 4, 16.0),
    (132, 33, 4, 7.0),
    (133, 33, 5, 7.0),
    (365, 33, 12, 7.0),
  ]) {
    test('$days days: $cols across, $rows rows, $size px', () {
      final layout = DotLayout.of(days: days, width: width);

      expect(layout.cols, cols);
      expect(layout.rows, rows);
      expect(layout.size, size);
    });
  }

  test('the gap is half a dot, kept between 3 and 8', () {
    expect(DotLayout.of(days: 15, width: width).gap, 8);
    expect(DotLayout.of(days: 132, width: width).gap, 4);
    expect(DotLayout.of(days: 365, width: 100).gap, 4);
  });

  test('a narrow card keeps the dots at 7 px', () {
    expect(DotLayout.of(days: 365, width: 100).size, 7);
  });
}

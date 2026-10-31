import 'package:exhale/core/theme/app_motion.dart';
import 'package:exhale/features/home/presentation/widgets/draining_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget ring(double fraction, Object restart, {bool reduceMotion = false}) =>
      MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: DrainingRing(
            fraction: fraction,
            restartKey: restart,
            size: 100,
            strokeWidth: 4,
            color: const Color(0xFFFFFFFF),
            track: const Color(0xFF000000),
          ),
        ),
      );

  double shown(WidgetTester tester) {
    final paint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(DrainingRing),
        matching: find.byType(CustomPaint),
      ),
    );
    return (paint.painter! as DrainingRingPainter).fill;
  }

  testWidgets("fills from empty at the main ring's pace", (tester) async {
    await tester.pumpWidget(ring(0.5, 1));
    expect(shown(tester), 0);

    await tester.pump(AppMotion.fill ~/ 2);
    final halfway = AppMotion.fillCurve.transform(0.5) * 0.5;
    expect(shown(tester), closeTo(halfway, 0.001));

    await tester.pump(AppMotion.fill ~/ 2);
    expect(shown(tester), 0.5);
  });

  testWidgets('follows the time without animating', (tester) async {
    await tester.pumpWidget(ring(0.5, 1));
    await tester.pump(AppMotion.fill);

    await tester.pumpWidget(ring(0.49, 1));

    expect(shown(tester), 0.49);
  });

  testWidgets('a new gap moves from where it was to the new position', (
    tester,
  ) async {
    await tester.pumpWidget(ring(0.5, 1));
    await tester.pump(AppMotion.fill);

    await tester.pumpWidget(ring(1, 2));
    expect(shown(tester), 0.5);

    await tester.pump(AppMotion.fill ~/ 2);
    final moved = 0.5 + AppMotion.fillCurve.transform(0.5) * 0.5;
    expect(shown(tester), closeTo(moved, 0.001));

    await tester.pump(AppMotion.fill ~/ 2);
    expect(shown(tester), 1);
  });

  testWidgets('Reduce Motion shows the position at once', (tester) async {
    await tester.pumpWidget(ring(0.5, 1, reduceMotion: true));
    expect(shown(tester), 0.5);

    await tester.pumpWidget(ring(1, 2, reduceMotion: true));
    expect(shown(tester), 1);
  });
}

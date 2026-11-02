import 'dart:math' as math;

import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/app_theme.dart';
import 'package:exhale/features/plan/presentation/widgets/limit_dial.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/haptics.dart';
import '../../helpers/large_text.dart';

void main() {
  /// Shows the dial and keeps its value, as the page does. Returns the values
  /// it was changed to.
  Future<List<int>> pumpDial(
    WidgetTester tester, {
    int value = 9,
    int planStartLimit = 12,
    String unitsLabel = 'sessions a day',
    String? gapLabel = 'One every 1 h 47 min',
    double textScale = 1,
    double width = 390,
  }) async {
    tester.view
      ..physicalSize = Size(width * 3, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final changes = <int>[];
    var current = value;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery.withClampedTextScaling(
          minScaleFactor: textScale,
          maxScaleFactor: textScale,
          child: Scaffold(
            body: Center(
              child: StatefulBuilder(
                builder: (context, setState) => LimitDial(
                  value: current,
                  planStartLimit: planStartLimit,
                  unitsLabel: unitsLabel,
                  gapLabel: gapLabel,
                  onChanged: (next) {
                    changes.add(next);
                    setState(() => current = next);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return changes;
  }

  Finder ring() => find
      .descendant(
        of: find.byType(LimitDial),
        matching: find.byType(CustomPaint),
      )
      .first;

  /// The ring's centre line at [fraction] of a turn, clockwise from the top.
  Offset onRing(WidgetTester tester, double fraction) {
    final angle = 2 * math.pi * fraction;
    return tester.getCenter(ring()) +
        Offset(96 * math.sin(angle), -96 * math.cos(angle));
  }

  test('scaleFor is the smallest multiple of 20 at least the larger', () {
    expect(LimitDial.scaleFor(planStartLimit: 12, value: 9), 20);
    expect(LimitDial.scaleFor(planStartLimit: 12, value: 21), 40);
    expect(LimitDial.scaleFor(planStartLimit: 45, value: 9), 60);
    expect(LimitDial.scaleFor(planStartLimit: 1, value: 80), 80);
    expect(LimitDial.scaleFor(planStartLimit: 20, value: 20), 20);
  });

  testWidgets('shows the value, its units and the gap', (tester) async {
    await pumpDial(tester);

    expect(find.text('9'), findsOneWidget);
    expect(find.text('sessions a day'), findsOneWidget);
    expect(find.text('One every 1 h 47 min'), findsOneWidget);
    expect(find.text('Drag the ring, or tap'), findsOneWidget);
  });

  testWidgets('with no gap only the units show', (tester) async {
    await pumpDial(tester, gapLabel: null);

    expect(find.text('sessions a day'), findsOneWidget);
    expect(find.textContaining('One every'), findsNothing);
  });

  group('buttons', () {
    testWidgets('− and + step by one', (tester) async {
      final changes = await pumpDial(tester);

      await tester.tap(find.byIcon(AppIcons.add));
      await tester.pump();
      await tester.tap(find.byIcon(AppIcons.remove));
      await tester.pump();
      await tester.tap(find.byIcon(AppIcons.remove));
      await tester.pump();

      expect(changes, [10, 9, 8]);
      expect(find.text('8'), findsOneWidget);
    });

    testWidgets('− stops at 1', (tester) async {
      final changes = await pumpDial(tester, value: 1);

      await tester.tap(find.byIcon(AppIcons.remove));
      await tester.pump();

      expect(changes, isEmpty);
    });

    testWidgets('+ passes the scale and stops at 80', (tester) async {
      final changes = await pumpDial(tester, value: 20);

      await tester.tap(find.byIcon(AppIcons.add));
      await tester.pump();
      expect(changes, [21]);

      final atTop = await pumpDial(tester, value: 80);
      await tester.pump();
      expect(find.text('80'), findsOneWidget);

      await tester.tap(find.byIcon(AppIcons.add));
      await tester.pump();
      expect(atTop, isEmpty);
    });
  });

  group('dragging', () {
    testWidgets('sets the value from the angle', (tester) async {
      final changes = await pumpDial(tester);

      final drag = await tester.startGesture(onRing(tester, 0.25));
      await tester.pump();
      await drag.moveTo(onRing(tester, 0.5));
      await tester.pump();
      await drag.up();

      expect(changes, [5, 10]);
    });

    testWidgets('past the top stops at the scale and does not wrap', (
      tester,
    ) async {
      final changes = await pumpDial(tester, value: 18);

      final drag = await tester.startGesture(onRing(tester, 0.9));
      await tester.pump();
      for (final fraction in [0.95, 1.0, 0.02, 0.05, 0.1]) {
        await drag.moveTo(onRing(tester, fraction));
        await tester.pump();
      }
      expect(changes, [19, 20]);

      await drag.moveTo(onRing(tester, 0.9));
      await tester.pump();
      await drag.up();

      expect(changes, [19, 20, 18]);
    });

    testWidgets('past the start stops at 1 and does not wrap', (tester) async {
      final changes = await pumpDial(tester, value: 2);

      final drag = await tester.startGesture(onRing(tester, 0.1));
      await tester.pump();
      for (final fraction in [0.02, 0.98, 0.95, 0.9]) {
        await drag.moveTo(onRing(tester, fraction));
        await tester.pump();
      }
      expect(changes, [1]);

      await drag.moveTo(onRing(tester, 0.1));
      await tester.pump();
      await drag.up();

      expect(changes, [1, 2]);
    });

    testWidgets('the scale holds until the finger lifts', (tester) async {
      // 30 of 40: a drag to 10 would shrink the scale to 20 under the finger.
      final changes = await pumpDial(tester, value: 30);

      final drag = await tester.startGesture(onRing(tester, 0.25));
      await tester.pump();
      await drag.moveTo(onRing(tester, 0.5));
      await tester.pump();
      await drag.up();
      await tester.pump();

      expect(changes, [10, 20]);
    });

    testWidgets('a vertical drag on the ring beats the page scrolling', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final changes = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              controller: controller,
              child: Column(
                children: [
                  LimitDial(
                    value: 9,
                    planStartLimit: 12,
                    unitsLabel: 'sessions a day',
                    gapLabel: null,
                    onChanged: changes.add,
                  ),
                  const SizedBox(height: 2000),
                ],
              ),
            ),
          ),
        ),
      );

      final drag = await tester.startGesture(onRing(tester, 0.2));
      await tester.pump();
      for (final fraction in [0.25, 0.3, 0.35]) {
        await drag.moveTo(onRing(tester, fraction));
        await tester.pump();
      }
      await drag.up();
      await tester.pump();

      expect(controller.offset, 0);
      expect(changes, isNotEmpty);
    });

    testWidgets('a drag from the middle scrolls the page', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final changes = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              controller: controller,
              child: Column(
                children: [
                  LimitDial(
                    value: 9,
                    planStartLimit: 12,
                    unitsLabel: 'sessions a day',
                    gapLabel: null,
                    onChanged: changes.add,
                  ),
                  const SizedBox(height: 2000),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.dragFrom(tester.getCenter(ring()), const Offset(0, -100));
      await tester.pump();

      expect(controller.offset, greaterThan(0));
      expect(changes, isEmpty);
    });
  });

  testWidgets('each change is a selection haptic', (tester) async {
    final played = recordHaptics(tester);
    await pumpDial(tester);

    await tester.tap(find.byIcon(AppIcons.add));
    await tester.pump();
    expect(played, ['HapticFeedbackType.selectionClick']);

    final drag = await tester.startGesture(onRing(tester, 0.25));
    await tester.pump();
    expect(played, hasLength(2));

    // Still rounds to 5 of 20: no change, no haptic.
    await drag.moveTo(onRing(tester, 0.255));
    await tester.pump();
    expect(played, hasLength(2));

    await drag.moveTo(onRing(tester, 0.3));
    await tester.pump();
    await drag.up();
    expect(played, hasLength(3));
  });

  group('semantics', () {
    testWidgets('one adjustable control', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpDial(tester);

      final node = tester.getSemantics(find.bySemanticsLabel('Daily limit'));
      final data = node.getSemanticsData();
      expect(data.value, '9 sessions a day');
      expect(data.hasAction(SemanticsAction.increase), isTrue);
      expect(data.hasAction(SemanticsAction.decrease), isTrue);
      expect(find.bySemanticsLabel('Fewer'), findsNothing);
      expect(find.bySemanticsLabel('More'), findsNothing);

      handle.dispose();
    });

    testWidgets('adjusting steps the value', (tester) async {
      final handle = tester.ensureSemantics();
      final changes = await pumpDial(tester);

      final node = tester.getSemantics(find.bySemanticsLabel('Daily limit'));
      node.owner!.performAction(node.id, SemanticsAction.increase);
      await tester.pump();

      expect(changes, [10]);

      handle.dispose();
    });

    testWidgets('no decrease at 1 and no increase at 80', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpDial(tester, value: 1);

      var data = tester
          .getSemantics(find.bySemanticsLabel('Daily limit'))
          .getSemanticsData();
      expect(data.hasAction(SemanticsAction.decrease), isFalse);

      await pumpDial(tester, value: 80);
      await tester.pump();

      data = tester
          .getSemantics(find.bySemanticsLabel('Daily limit'))
          .getSemanticsData();
      expect(data.hasAction(SemanticsAction.increase), isFalse);

      handle.dispose();
    });
  });

  testWidgets('at 200% on an SE width nothing overflows or clips', (
    tester,
  ) async {
    await loadAppFonts();
    await pumpDial(
      tester,
      value: 80,
      unitsLabel: 'cups of coffee a day',
      gapLabel: 'One every 11 h 47 min',
      textScale: 2,
      width: 280,
    );

    expect(tester.takeException(), isNull);
    expect(tester.clippedTexts(), isEmpty);
  });
}

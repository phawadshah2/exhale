import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/theme/app_theme.dart';
import 'package:exhale/features/plan/presentation/widgets/quit_ruler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/haptics.dart';

void main() {
  final today = LogicalDay(2026, 10, 16);
  const width = 350.0;

  /// Shows the ruler and keeps its date, as the page does. Returns the dates
  /// it was changed to.
  Future<List<LogicalDay>> pumpRuler(
    WidgetTester tester, {
    LogicalDay? selected,
    int spanDays = 119,
  }) async {
    final changes = <LogicalDay>[];
    var current = selected ?? today.addDays(60);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: StatefulBuilder(
                builder: (context, setState) => QuitRuler(
                  today: today,
                  selected: current,
                  spanDays: spanDays,
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

  Offset at(WidgetTester tester, double dx) =>
      tester.getTopLeft(find.byType(QuitRuler)) + Offset(dx, 20);

  group('layout', () {
    test('a tick a week up to 40 weeks, every 4th taller', () {
      final ticks = RulerLayout(today: today, spanDays: 280).ticks;

      expect(ticks, hasLength(41));
      expect(ticks.take(5).map((tick) => tick.days), [0, 7, 14, 21, 28]);
      expect(ticks.take(5).map((tick) => tick.tall), [
        true,
        false,
        false,
        false,
        true,
      ]);
      expect(ticks.last.days, 280);
    });

    test('past 40 weeks a tick every 4 weeks', () {
      final ticks = RulerLayout(today: today, spanDays: 281).ticks;

      expect(ticks.take(3).map((tick) => tick.days), [0, 28, 56]);
      expect(ticks.last.days, 280);
      expect(ticks.every((tick) => tick.tall), isTrue);
    });

    test('month names sit at their first days', () {
      final months = RulerLayout(
        today: today,
        spanDays: 119,
      ).months(width: width);

      expect(months.map((month) => month.name), ['Nov', 'Dec', 'Jan', 'Feb']);
      expect(months.map((month) => month.days), [16, 46, 77, 108]);
    });

    test('a ruler starting on the 1st names that month', () {
      final months = RulerLayout(
        today: LogicalDay(2026, 11, 1),
        spanDays: 40,
      ).months(width: width);

      expect(months.map((month) => month.name), ['Nov', 'Dec']);
      expect(months.first.days, 0);
    });

    test('a long ruler drops names that would touch', () {
      final months = RulerLayout(
        today: today,
        spanDays: 1000,
      ).months(width: width);
      final all = RulerLayout(
        today: today,
        spanDays: 1000,
      ).months(width: 100000);

      expect(months.length, lessThan(all.length));
      for (var i = 1; i < months.length; i++) {
        final gap = (months[i].days - months[i - 1].days) / 1000 * width;
        expect(gap, greaterThanOrEqualTo(RulerLayout.minMonthGap));
      }
    });
  });

  group('dragging', () {
    testWidgets('gives the nearest day', (tester) async {
      final changes = await pumpRuler(tester);

      final drag = await tester.startGesture(at(tester, 100));
      await drag.moveTo(at(tester, 175));
      await tester.pump();
      await drag.moveTo(at(tester, 176));
      await tester.pump();
      await drag.up();

      // 175 of 350 across 119 days is 59.5, which rounds to 60.
      expect(changes.last, today.addDays(60));
      expect(changes.first, today.addDays(34));
    });

    testWidgets('stops at tomorrow', (tester) async {
      final changes = await pumpRuler(tester);

      final drag = await tester.startGesture(at(tester, 100));
      await drag.moveTo(at(tester, -50));
      await tester.pump();
      await drag.up();

      expect(changes.last, today.addDays(1));
    });

    testWidgets('stops at the end of the span', (tester) async {
      final changes = await pumpRuler(tester);

      final drag = await tester.startGesture(at(tester, 100));
      await drag.moveTo(at(tester, width + 50));
      await tester.pump();
      await drag.up();

      expect(changes.last, today.addDays(119));
    });

    testWidgets('a vertical drag scrolls the page and leaves the date alone', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final changes = <LogicalDay>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              controller: controller,
              child: Column(
                children: [
                  QuitRuler(
                    today: today,
                    selected: today.addDays(60),
                    spanDays: 119,
                    onChanged: changes.add,
                  ),
                  const SizedBox(height: 2000),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.dragFrom(at(tester, 100), const Offset(0, -80));
      await tester.pump();

      expect(controller.offset, greaterThan(0));
      expect(changes, isEmpty);
    });

    testWidgets('a selection haptic on each tick, not each day', (
      tester,
    ) async {
      final played = recordHaptics(tester);
      await pumpRuler(tester, selected: today.addDays(70));
      const perDay = width / 119;

      // Day 71, then 72: both between the ticks at 70 and 77.
      final drag = await tester.startGesture(at(tester, 71 * perDay));
      await drag.moveTo(at(tester, 72 * perDay));
      await tester.pump();
      expect(played, isEmpty);

      await drag.moveTo(at(tester, 78 * perDay));
      await tester.pump();
      await drag.up();

      expect(played, ['HapticFeedbackType.selectionClick']);
    });
  });

  group('semantics', () {
    testWidgets('reads the date and how far away it is', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpRuler(tester);

      final data = tester
          .getSemantics(find.bySemanticsLabel('Quit date'))
          .getSemanticsData();
      expect(data.value, 'Dec 15, 60 days away');
      expect(data.hasAction(SemanticsAction.increase), isTrue);
      expect(data.hasAction(SemanticsAction.decrease), isTrue);

      handle.dispose();
    });

    testWidgets('one day away reads in the singular and cannot go earlier', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpRuler(tester, selected: today.addDays(1));

      final data = tester
          .getSemantics(find.bySemanticsLabel('Quit date'))
          .getSemanticsData();
      expect(data.value, 'Oct 17, 1 day away');
      expect(data.hasAction(SemanticsAction.decrease), isFalse);

      handle.dispose();
    });

    testWidgets('adjusting moves one day', (tester) async {
      final handle = tester.ensureSemantics();
      final changes = await pumpRuler(tester);

      final node = tester.getSemantics(find.bySemanticsLabel('Quit date'));
      node.owner!.performAction(node.id, SemanticsAction.increase);
      await tester.pump();

      expect(changes, [today.addDays(61)]);

      handle.dispose();
    });
  });
}

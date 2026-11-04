import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/features/home/presentation/widgets/history/month_ring_calendar.dart';
import 'package:exhale/features/home/presentation/widgets/history/week_line_chart.dart';
import 'package:exhale/features/logs/presentation/pages/logs_page.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/tracking/domain/entities/period_range.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:exhale/features/tracking/domain/usecases/add_habit_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/pump_app.dart';

void main() {
  // Friday 16 Oct 2026, 15:42. Plan from Wed Oct 14, 9 a day, quit Dec 16.
  final now = DateTime(2026, 10, 16, 15, 42);

  setUp(() => setUpTestDependencies(FixedClock(now)));
  tearDown(InjectionContainer.reset);

  Future<void> logAt(DateTime at, {int times = 1, Trigger? trigger}) async {
    for (var i = 0; i < times; i++) {
      await sl<AddHabitLog>()(
        AddHabitLogInput(
          habitId: 1,
          loggedAt: at.add(Duration(minutes: i)),
          trigger: trigger,
        ),
      );
    }
  }

  // 6 on Oct 14, 6 on Oct 15, 4 on Oct 16; four triggers, Boredom first.
  Future<void> seedWeek() async {
    await seedHabit(
      PlanDraft(
        startDay: LogicalDay(2026, 10, 14),
        startLimit: 9,
        quitDay: LogicalDay(2026, 12, 16),
      ),
    );
    await logAt(DateTime(2026, 10, 14, 9), times: 3, trigger: Trigger.stress);
    await logAt(DateTime(2026, 10, 14, 12), times: 2, trigger: Trigger.work);
    await logAt(DateTime(2026, 10, 14, 15), trigger: Trigger.social);
    await logAt(DateTime(2026, 10, 15, 9), times: 6, trigger: Trigger.boredom);
    await logAt(DateTime(2026, 10, 16, 9), times: 4);
  }

  Future<void> showHistory(WidgetTester tester) async {
    await tester.pumpAppPastSplash(height: 2400);
    await tester.ensureVisible(find.text('History'));
    await tester.pumpAndSettle();
  }

  testWidgets('week shows total and stats line', (tester) async {
    await seedWeek();
    await showHistory(tester);

    expect(find.text('16 / 45 allowed'), findsOneWidget);
    expect(find.text('11 under'), findsOneWidget);
    expect(find.text('Avg 5.3/day'), findsOneWidget);
    expect(find.text('0 days over'), findsOneWidget);
    expect(find.text('3 days on track'), findsOneWidget);
    expect(find.text('This week'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('arrows move a week back and forth', (tester) async {
    await seedWeek();
    await showHistory(tester);

    await tester.tap(find.byTooltip('Previous week'));
    await tester.pumpAndSettle();
    expect(find.text('Oct 5 – 11'), findsOneWidget);
    expect(find.text('0 / 0 allowed'), findsOneWidget);

    await tester.tap(find.byTooltip('Next week'));
    await tester.pumpAndSettle();
    expect(find.text('This week'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('month shows the ring calendar and colour key', (tester) async {
    await seedWeek();
    await showHistory(tester);

    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();

    expect(find.text('16 / 147 allowed'), findsOneWidget);
    expect(find.text('Under'), findsOneWidget);
    expect(find.text('At limit'), findsOneWidget);
    expect(find.text('Over'), findsOneWidget);
    expect(find.text('Before plan'), findsOneWidget);
    expect(find.text('31'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('the Under key is green', (tester) async {
    await seedWeek();
    await showHistory(tester);
    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();

    final swatch = tester.widget<Container>(
      find.descendant(
        of: find.ancestor(of: find.text('Under'), matching: find.byType(Row)),
        matching: find.byType(Container),
      ),
    );
    final context = tester.element(find.text('Under'));
    expect(
      (swatch.decoration! as BoxDecoration).color,
      context.exhale.success.solid,
    );

    await tester.disposeApp();
  });

  testWidgets('week points under the limit are green, the line the accent', (
    tester,
  ) async {
    await seedWeek();
    await showHistory(tester);

    final chart = find
        .descendant(
          of: find.byType(WeekLineChart),
          matching: find.byType(CustomPaint),
        )
        .first;
    final context = tester.element(chart);
    final green = context.exhale.success.solid;
    final accent = context.colors.primaryContainer;
    // Paint keeps 8 bits a channel, so compare as ARGB.
    expect(
      tester.renderObject(chart),
      paints..something(
        (call, args) =>
            call == #drawCircle &&
            (args[2] as Paint).style == PaintingStyle.stroke &&
            (args[2] as Paint).color.toARGB32() == green.toARGB32(),
      ),
    );
    expect(
      tester.renderObject(chart),
      paints..something(
        (call, args) =>
            call == #drawPath &&
            (args[1] as Paint).strokeWidth == 3 &&
            (args[1] as Paint).color.toARGB32() == accent.toARGB32(),
      ),
    );

    await tester.disposeApp();
  });

  testWidgets('month keeps one height and greys the neighbouring days', (
    tester,
  ) async {
    await seedWeek();
    await showHistory(tester);
    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();

    expect(
      MonthRingCalendar.heightOf(PeriodRange.monthOf(LogicalDay(2027, 2, 10))),
      MonthRingCalendar.heightOf(PeriodRange.monthOf(LogicalDay(2026, 10, 1))),
    );

    final calendar = find.byType(MonthRingCalendar);
    // Oct 2026 starts on a Thursday: Sep 28 to 30 lead and Nov 1 to 8 trail.
    final september = find.descendant(of: calendar, matching: find.text('30'));
    final november = find.descendant(of: calendar, matching: find.text('1'));
    expect(september, findsNWidgets(2));
    expect(november, findsNWidgets(2));

    final before = find.byType(LogsPage);
    await tester.tap(november.last);
    await tester.pumpAndSettle();
    expect(before, findsNothing);

    await tester.disposeApp();
  });

  testWidgets('month rings are thin and the future ones are dotted', (
    tester,
  ) async {
    await seedWeek();
    await showHistory(tester);
    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();

    final rings = find.descendant(
      of: find.byType(MonthRingCalendar),
      matching: find.byType(CustomPaint),
    );
    // Oct 1 is before the plan, Oct 17 is in the future.
    expect(tester.renderObject(rings.at(0)), paints..arc(strokeWidth: 3));
    expect(tester.renderObject(rings.at(16)), isNot(paints..arc()));
    expect(tester.renderObject(rings.at(16)), paints..path());

    await tester.disposeApp();
  });

  testWidgets('week line and day dots are thin', (tester) async {
    await seedWeek();
    await showHistory(tester);

    final chart = tester.renderObject(
      find
          .descendant(
            of: find.byType(WeekLineChart),
            matching: find.byType(CustomPaint),
          )
          .first,
    );
    bool stroked(Symbol call, List<dynamic> args, double width) =>
        call == #drawPath && (args[1] as Paint).strokeWidth == width;
    expect(chart, paints..something((c, args) => stroked(c, args, 3)));
    expect(
      chart,
      paints..something(
        (call, args) =>
            call == #drawCircle &&
            args[1] == 4 &&
            (args[2] as Paint).strokeWidth == 2,
      ),
    );

    await tester.disposeApp();
  });

  testWidgets('a toggle swaps to stats loaded ahead, then settles on one', (
    tester,
  ) async {
    await seedWeek();
    await showHistory(tester);

    await tester.tap(find.text('Month'));
    await tester.pump();
    // The total counts up from 0; its allowance is the new period's at once.
    expect(find.textContaining('/ 147 allowed'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('16 / 45 allowed'), findsNothing);
    expect(find.text('TOP TRIGGERS'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('all shows since-day-1 label', (tester) async {
    await seedWeek();
    await showHistory(tester);

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    expect(find.text('Since Oct 14 · day 3 of 63'), findsOneWidget);
    expect(find.text('16 / 27 allowed'), findsOneWidget);
    expect(find.text('Your days'), findsOneWidget);
    expect(find.text('Your plan'), findsWidgets);
    expect(find.text('TOP TRIGGERS SINCE DAY 1'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('top triggers capped at 3 with All triggers link', (
    tester,
  ) async {
    await seedWeek();
    await showHistory(tester);

    expect(find.textContaining('Boredom ·'), findsOneWidget);
    expect(find.textContaining('Stress ·'), findsOneWidget);
    expect(find.textContaining('Work ·'), findsOneWidget);
    expect(find.textContaining('Social ·'), findsNothing);
    expect(find.text('All triggers ›'), findsOneWidget);

    await tester.tap(find.text('All triggers ›'));
    await tester.pumpAndSettle();

    expect(find.text('The evidence.'), findsOneWidget);
    expect(
      find.text('16 / 45 (27 so far) allowed', findRichText: true),
      findsOneWidget,
    );

    await tester.disposeApp();
  });

  testWidgets('tapping Wednesday opens Logs for Oct 14', (tester) async {
    final semantics = tester.ensureSemantics();
    await seedWeek();
    await showHistory(tester);

    await tester.tap(find.bySemanticsLabel('Wednesday, Oct 14: 6 of 9'));
    await tester.pumpAndSettle();

    expect(find.text('The evidence.'), findsOneWidget);
    expect(find.text('Wed, Oct 14'), findsOneWidget);

    await tester.disposeApp();
    semantics.dispose();
  });

  testWidgets('tapping a trigger chip opens Logs for the period and trigger', (
    tester,
  ) async {
    await seedWeek();
    await showHistory(tester);

    await tester.tap(find.textContaining('Work ·'));
    await tester.pumpAndSettle();

    // Today has no Work logs, so it opens on Oct 14, which has both.
    expect(find.text('The evidence.'), findsOneWidget);
    expect(find.text('Wed, Oct 14'), findsOneWidget);
    expect(find.text('No Work logs this day.'), findsNothing);
    expect(find.byType(Dismissible), findsNWidgets(2));

    await tester.disposeApp();
  });

  testWidgets('each day has a semantics label with its count and limit', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await seedWeek();
    await showHistory(tester);

    expect(find.bySemanticsLabel('Wednesday, Oct 14: 6 of 9'), findsOneWidget);
    expect(find.bySemanticsLabel('Thursday, Oct 15: 6 of 9'), findsOneWidget);
    expect(find.bySemanticsLabel('Friday, Oct 16: 4 of 9'), findsOneWidget);

    await tester.disposeApp();
    semantics.dispose();
  });
}

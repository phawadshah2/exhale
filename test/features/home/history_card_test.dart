import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
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

    expect(find.text('Logs'), findsOneWidget);
    expect(find.text('16 logged'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('tapping Wednesday opens Logs for Oct 14', (tester) async {
    final semantics = tester.ensureSemantics();
    await seedWeek();
    await showHistory(tester);

    await tester.tap(find.bySemanticsLabel('Wednesday, Oct 14: 6 of 9'));
    await tester.pumpAndSettle();

    expect(find.text('Logs'), findsOneWidget);
    expect(find.text('Wednesday, Oct 14'), findsOneWidget);

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

    expect(find.text('Logs'), findsOneWidget);
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

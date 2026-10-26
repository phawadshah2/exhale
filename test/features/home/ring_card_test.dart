import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/home/presentation/widgets/day_triggers.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:exhale/features/tracking/domain/usecases/add_habit_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/pump_app.dart';

void main() {
  // Friday 16 Oct 2026, 15:42.
  final now = DateTime(2026, 10, 16, 15, 42);
  final today = LogicalDay(2026, 10, 16);

  setUp(() => setUpTestDependencies(FixedClock(now)));
  tearDown(InjectionContainer.reset);

  Future<int> startPlan(LogicalDay start, {int limit = 9}) => seedHabit(
    PlanDraft(
      startDay: start,
      startLimit: limit,
      quitDay: start.addDays(limit * 7),
    ),
  );

  Future<void> logAt(
    DateTime at, {
    int times = 1,
    Trigger? trigger,
    String? note,
  }) async {
    for (var i = 0; i < times; i++) {
      await sl<AddHabitLog>()(
        AddHabitLogInput(
          habitId: 1,
          loggedAt: at.add(Duration(minutes: i)),
          trigger: trigger,
          note: note,
        ),
      );
    }
  }

  String countText(WidgetTester tester) {
    final text = tester.widget<Text>(find.byKey(const Key('day-count')));
    return text.textSpan?.toPlainText() ?? text.data!;
  }

  IconButton button(WidgetTester tester, String tooltip) => tester.widget(
    find.ancestor(
      of: find.byTooltip(tooltip),
      matching: find.byType(IconButton),
    ),
  );

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('steps back a day and returns to today', (tester) async {
    await startPlan(LogicalDay(2026, 10, 14));
    await logAt(DateTime(2026, 10, 15, 9), times: 3);
    await tester.pumpAppPastSplash(height: 2400);

    expect(button(tester, 'Next day').onPressed, isNull);

    await tapAndSettle(tester, find.byTooltip('Previous day'));
    expect(find.text('Thursday, Oct 15'), findsOneWidget);
    expect(countText(tester), '3 / 9');
    expect(find.text('6 under limit'), findsOneWidget);
    expect(find.text('Limit that day'), findsOneWidget);

    await tapAndSettle(tester, find.text('Today'));
    expect(find.text("Today's Consumption"), findsOneWidget);
    expect(countText(tester), '0 / 9');

    await tester.disposeApp();
  });

  testWidgets('swiping right goes to the day before', (tester) async {
    await startPlan(LogicalDay(2026, 10, 14));
    await logAt(DateTime(2026, 10, 15, 9), times: 2);
    await tester.pumpAppPastSplash(height: 2400);

    await tester.fling(
      find.byKey(const Key('day-count')),
      const Offset(300, 0),
      1000,
    );
    await tester.pumpAndSettle();

    expect(find.text('Thursday, Oct 15'), findsOneWidget);
    expect(countText(tester), '2 / 9');

    await tester.disposeApp();
  });

  testWidgets('going back stops 30 days before the plan', (tester) async {
    await startPlan(today);
    await tester.pumpAppPastSplash(height: 2400);

    // 30 days before Fri 16 Oct is Wed 16 Sep.
    for (var i = 0; i < 30; i++) {
      await tester.tap(find.byTooltip('Previous day'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Wednesday, Sep 16'), findsOneWidget);
    expect(button(tester, 'Previous day').onPressed, isNull);
    expect(find.text('Before your plan'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('a back-filled day before the plan leaves stats alone', (
    tester,
  ) async {
    await startPlan(LogicalDay(2026, 10, 14));
    await logAt(DateTime(2026, 10, 14, 9), times: 6);
    await logAt(DateTime(2026, 10, 15, 9), times: 6);
    await tester.pumpAppPastSplash(height: 2400);

    for (var i = 0; i < 4; i++) {
      await tapAndSettle(tester, find.byTooltip('Previous day'));
    }
    expect(find.text('Monday, Oct 12'), findsOneWidget);
    expect(countText(tester), '0');
    expect(find.text('Before your plan'), findsWidgets);

    await tapAndSettle(tester, find.text('Add missed log'));
    await tester.scrollAndTap(find.text('Add log'));
    await tester.pumpAndSettle();

    expect(countText(tester), '1');

    await tester.ensureVisible(find.text('Avoided'));
    await tester.pumpAndSettle();
    expect(find.text('6 cigs'), findsOneWidget);
    expect(find.text('3 Days'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('shows last entry and last trigger', (tester) async {
    await startPlan(LogicalDay(2026, 10, 14));
    await logAt(
      DateTime(2026, 10, 16, 15, 18),
      trigger: Trigger.stress,
      note: 'Deadline',
    );
    await tester.pumpAppPastSplash(height: 2400);

    expect(find.text('24m ago'), findsOneWidget);
    expect(find.text('3:18 PM'), findsWidgets);
    expect(find.text('Last trigger'), findsOneWidget);
    expect(find.text('Stress'), findsWidgets);
    expect(find.text('Deadline'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets("today's triggers show the top 3 with counts", (tester) async {
    await startPlan(LogicalDay(2026, 10, 14));
    await logAt(DateTime(2026, 10, 16, 7), trigger: Trigger.boredom);
    await logAt(DateTime(2026, 10, 16, 8), times: 2, trigger: Trigger.stress);
    await logAt(DateTime(2026, 10, 16, 10), trigger: Trigger.social);
    await logAt(DateTime(2026, 10, 16, 11), trigger: Trigger.coffee);
    await tester.pumpAppPastSplash(height: 2400);

    expect(find.text("TODAY'S TRIGGERS · TAP TO SEE LOGS"), findsOneWidget);
    expect(find.text('2 · 40%'), findsOneWidget);
    expect(find.text('1 · 20%'), findsNWidgets(2));
    expect(
      find.descendant(
        of: find.byType(DayTriggers),
        matching: find.text('Boredom'),
      ),
      findsNothing,
    );

    await tester.disposeApp();
  });

  testWidgets("a trigger row opens that day's logs for the trigger", (
    tester,
  ) async {
    await startPlan(LogicalDay(2026, 10, 14));
    await logAt(DateTime(2026, 10, 16, 8), times: 2, trigger: Trigger.stress);
    await logAt(DateTime(2026, 10, 16, 10), trigger: Trigger.work);
    await tester.pumpAppPastSplash(height: 2400);

    await tapAndSettle(
      tester,
      find.descendant(
        of: find.byType(DayTriggers),
        matching: find.text('Stress'),
      ),
    );

    expect(find.text('Logs'), findsOneWidget);
    expect(find.text('2 of 3 logs today · 67%'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets("a past day shows that day's triggers", (tester) async {
    await startPlan(LogicalDay(2026, 10, 14));
    await logAt(DateTime(2026, 10, 15, 9), trigger: Trigger.work);
    await tester.pumpAppPastSplash(height: 2400);

    await tapAndSettle(tester, find.byTooltip('Previous day'));

    expect(find.text("THAT DAY'S TRIGGERS · TAP TO SEE LOGS"), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
    expect(find.text('1 · 100%'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('the first day shows a placeholder for triggers', (tester) async {
    await startPlan(today);
    await tester.pumpAppPastSplash(height: 2400);

    expect(
      find.text("Today's triggers show here once you log."),
      findsOneWidget,
    );

    await tester.disposeApp();
  });

  testWidgets('stepping the ring does not move the History card', (
    tester,
  ) async {
    await startPlan(LogicalDay(2026, 10, 1));
    await tester.pumpAppPastSplash(height: 2400);

    for (var i = 0; i < 8; i++) {
      await tester.tap(find.byTooltip('Previous day'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Thursday, Oct 8'), findsOneWidget);

    await tester.ensureVisible(find.text('This week'));
    await tester.pumpAndSettle();
    expect(find.text('This week'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('going over the limit shows a supportive note', (tester) async {
    await startPlan(LogicalDay(2026, 10, 14), limit: 3);
    await logAt(DateTime(2026, 10, 16, 9), times: 5);
    await tester.pumpAppPastSplash(height: 2400);

    expect(
      find.textContaining('A harder day. Tomorrow starts fresh at'),
      findsOneWidget,
    );

    await tester.disposeApp();
  });
}

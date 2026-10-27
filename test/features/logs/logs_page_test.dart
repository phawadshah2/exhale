import 'dart:async';

import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/logs/presentation/logs_query.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:exhale/features/tracking/domain/usecases/add_habit_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/pump_app.dart';

void main() {
  // Friday 16 Oct 2026, 15:42. The week runs Mon 12 to Sun 18 Oct.
  final now = DateTime(2026, 10, 16, 15, 42);
  final today = LogicalDay(2026, 10, 16);

  setUp(() => setUpTestDependencies(FixedClock(now)));
  tearDown(InjectionContainer.reset);

  // Plan from Wed 14 Oct: the limit is 9 on the 14th, 15th and 16th.
  Future<void> startPlan() => seedHabit(
    PlanDraft(
      startDay: LogicalDay(2026, 10, 14),
      startLimit: 9,
      quitDay: LogicalDay(2026, 10, 14).addDays(63),
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

  Future<void> openPage(WidgetTester tester, LogsQuery query) async {
    await tester.pumpAppPastSplash(height: 2400);
    final context = tester.element(find.byType(Scaffold).first);
    unawaited(GoRouter.of(context).push(query.toUri().toString()));
    await tester.pumpAndSettle();
  }

  testWidgets('groups by logical day with allowed counts', (tester) async {
    await startPlan();
    await logAt(DateTime(2026, 10, 15, 9), times: 2);
    // After midnight, before the 4 AM reset: still the 15th.
    await logAt(DateTime(2026, 10, 16, 1, 30));
    await logAt(DateTime(2026, 10, 16, 9), times: 4);
    await openPage(tester, const LogsQuery(habitId: 1));

    expect(find.text('Today · Fri, Oct 16'), findsOneWidget);
    expect(find.text('4 of 9 allowed'), findsOneWidget);
    expect(find.text('Yesterday · Thu, Oct 15'), findsOneWidget);
    expect(find.text('3 of 9 allowed'), findsOneWidget);
    expect(find.text('Wed, Oct 14'), findsOneWidget);
    expect(find.text('0 of 9 allowed'), findsOneWidget);
    expect(find.text('Add a missed log for this day'), findsOneWidget);
    expect(find.text('7 logged'), findsOneWidget);
    expect(find.text('No trigger'), findsWidgets);
    expect(
      find.text('Tap a log to edit · swipe left to delete'),
      findsOneWidget,
    );

    await tester.disposeApp();
  });

  testWidgets("one day plus a trigger shows the trigger's share and "
      "today's allowance", (tester) async {
    await startPlan();
    await logAt(DateTime(2026, 10, 16, 8), times: 2, trigger: Trigger.stress);
    await logAt(DateTime(2026, 10, 16, 10), times: 2, trigger: Trigger.work);
    await openPage(
      tester,
      LogsQuery(habitId: 1, from: today, to: today, trigger: Trigger.stress),
    );

    expect(find.text('2 of 4 logs today · 50%'), findsOneWidget);
    expect(find.text('Allowed today: 4 of 9 used · 5 left'), findsOneWidget);
    expect(find.byType(Dismissible), findsNWidgets(2));

    await tester.disposeApp();
  });

  testWidgets('trigger chip filters the list and shows a removable chip', (
    tester,
  ) async {
    await startPlan();
    await logAt(DateTime(2026, 10, 15, 9), trigger: Trigger.stress);
    await logAt(DateTime(2026, 10, 15, 11), trigger: Trigger.work);
    await openPage(tester, const LogsQuery(habitId: 1));

    expect(find.byType(Dismissible), findsNWidgets(2));

    await tester.tap(find.text('Stress · 1 · 50%'));
    await tester.pumpAndSettle();

    expect(find.byType(Dismissible), findsOneWidget);
    expect(find.byTooltip('Remove Stress filter'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove Stress filter'));
    await tester.pumpAndSettle();

    expect(find.byType(Dismissible), findsNWidgets(2));
    expect(find.byTooltip('Remove Stress filter'), findsNothing);

    await tester.disposeApp();
  });

  testWidgets('swipe left deletes after confirm and Undo restores', (
    tester,
  ) async {
    await startPlan();
    await logAt(DateTime(2026, 10, 16, 9), times: 2);
    await openPage(tester, const LogsQuery(habitId: 1));

    expect(find.text('2 of 9 allowed'), findsOneWidget);

    await tester.drag(find.byType(Dismissible).first, const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(find.text('1 of 9 allowed'), findsOneWidget);
    expect(find.text('Log deleted'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(find.text('2 of 9 allowed'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('long day collapses to 3 with Show more', (tester) async {
    await startPlan();
    await logAt(DateTime(2026, 10, 16, 9), times: 5);
    await openPage(tester, const LogsQuery(habitId: 1));

    expect(find.byType(Dismissible), findsNWidgets(3));

    await tester.tap(find.text('Show 2 more'));
    await tester.pumpAndSettle();

    expect(find.byType(Dismissible), findsNWidgets(5));
    expect(find.text('Show 2 more'), findsNothing);

    await tester.disposeApp();
  });

  testWidgets('Show more stays with its day when paging weeks', (tester) async {
    await startPlan();
    await logAt(DateTime(2026, 10, 16, 9), times: 5);
    await logAt(DateTime(2026, 10, 9, 9), times: 5);
    await openPage(tester, const LogsQuery(habitId: 1));

    await tester.tap(find.text('Show 2 more'));
    await tester.pumpAndSettle();
    expect(find.byType(Dismissible), findsNWidgets(5));

    await tester.tap(find.byTooltip('Previous week'));
    await tester.pumpAndSettle();

    expect(find.text('Fri, Oct 9'), findsOneWidget);
    expect(find.byType(Dismissible), findsNWidgets(3));
    expect(find.text('Show 2 more'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('a week with nothing tracked shows no under or over pill', (
    tester,
  ) async {
    await startPlan();
    await logAt(DateTime(2026, 10, 9, 9), times: 2);
    await openPage(
      tester,
      LogsQuery(
        habitId: 1,
        from: LogicalDay(2026, 10, 5),
        to: LogicalDay(2026, 10, 11),
      ),
    );

    expect(find.text('0 logged'), findsOneWidget);
    expect(find.textContaining(' under'), findsNothing);
    expect(find.textContaining(' over'), findsNothing);
    expect(find.text('At limit'), findsNothing);

    await tester.disposeApp();
  });

  testWidgets('the period pill reads under at the limit, like History', (
    tester,
  ) async {
    await startPlan();
    // 9 a day on the 14th to the 16th: 27 allowed by today.
    await logAt(DateTime(2026, 10, 15, 9), times: 27);
    await openPage(tester, const LogsQuery(habitId: 1));

    expect(find.text('0 under'), findsOneWidget);
    expect(find.text('At limit'), findsNothing);

    await tester.disposeApp();
  });

  testWidgets('previous week stops 30 days before the plan', (tester) async {
    await startPlan();
    await openPage(tester, const LogsQuery(habitId: 1));

    IconButton previous() => tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip('Previous week'),
        matching: find.byType(IconButton),
      ),
    );

    // The plan starts Wed 14 Oct; the earliest day is Mon 14 Sep.
    for (var i = 0; i < 4; i++) {
      expect(previous().onPressed, isNotNull);
      await tester.tap(find.byTooltip('Previous week'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Sep 14 – 20'), findsOneWidget);
    expect(previous().onPressed, isNull);

    await tester.disposeApp();
  });

  testWidgets('day before the plan shows no limit', (tester) async {
    await startPlan();
    await logAt(DateTime(2026, 10, 13, 9), times: 2);
    await logAt(DateTime(2026, 10, 15, 9));
    await openPage(tester, const LogsQuery(habitId: 1));

    expect(find.text('Tue, Oct 13'), findsOneWidget);
    expect(find.text('Before your plan'), findsOneWidget);
    expect(find.text('1 logged'), findsOneWidget);

    await tester.disposeApp();
  });
}

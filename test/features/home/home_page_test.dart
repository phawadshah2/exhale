import 'dart:async';

import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/domain/entities/habit_draft.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:exhale/features/habit/domain/usecases/add_habit.dart';
import 'package:exhale/features/habit/domain/usecases/archive_habit.dart';
import 'package:exhale/features/home/presentation/pages/home_page.dart';
import 'package:exhale/features/logs/presentation/logs_query.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/usecases/save_settings.dart';
import 'package:exhale/features/tracking/domain/entities/habit_log.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:exhale/features/tracking/domain/repositories/habit_log_repository.dart';
import 'package:exhale/features/tracking/domain/usecases/add_habit_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/pump_app.dart';

void main() {
  // Friday 16 Oct 2026, 15:42.
  final now = DateTime(2026, 10, 16, 15, 42);
  final today = LogicalDay(2026, 10, 16);

  setUp(() => setUpTestDependencies(FixedClock(now)));
  tearDown(InjectionContainer.reset);

  Future<int> startPlan(
    LogicalDay start, {
    int limit = 9,
    Habit habit = Habit.smoking,
    String? reason,
    int? priceCents,
  }) => seedHabit(
    PlanDraft(
      startDay: start,
      startLimit: limit,
      quitDay: start.addDays(limit * 7),
    ),
    habit: habit,
    reason: reason,
    priceCents: priceCents,
  );

  Future<void> logOn(DateTime at, {int times = 1, int habitId = 1}) async {
    for (var i = 0; i < times; i++) {
      await sl<AddHabitLog>()(
        AddHabitLogInput(
          habitId: habitId,
          loggedAt: at.add(Duration(minutes: i)),
        ),
      );
    }
  }

  String countText(WidgetTester tester) {
    final text = tester.widget<Text>(find.byKey(const Key('day-count')));
    return text.textSpan?.toPlainText() ?? text.data!;
  }

  Future<List<HabitLog>> storedLogs(WidgetTester tester) async {
    final logs = await tester.runAsync(
      () => sl<HabitLogRepository>()
          .watchLogs(habitId: 1, from: DateTime(2026), to: DateTime(2027))
          .first,
    );
    return logs!;
  }

  Future<List<Trigger?>> storedTriggers(WidgetTester tester) async =>
      (await storedLogs(tester)).map((log) => log.trigger).toList();

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('first day: empty state, stage and next drop', (tester) async {
    await startPlan(today);
    await tester.pumpAppPastSplash(height: 2400);

    expect(countText(tester), '0 / 9');
    expect(find.text('9 left today'), findsOneWidget);
    expect(find.text('On track'), findsOneWidget);
    expect(
      find.text('No cigarettes logged today. Nice start.'),
      findsOneWidget,
    );
    expect(find.text('Stage 1 of 9 · Daily limit: 9'), findsOneWidget);
    expect(find.text('Plan started today'), findsOneWidget);
    expect(find.text('Drops to 8 in 7d'), findsOneWidget);
    expect(find.text('D1'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('logging asks for a trigger and stores it', (tester) async {
    await startPlan(today);
    await tester.pumpAppPastSplash(height: 2400);

    await tester.scrollAndTap(find.byTooltip('Log'));
    await tester.pumpAndSettle();
    expect(find.text('What triggered this one?'), findsOneWidget);

    await tester.tap(find.text('Coffee'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpInSteps(const Duration(milliseconds: 900));

    expect(countText(tester), '1 / 9');
    expect(find.text('Logged at 3:42 PM'), findsOneWidget);
    expect(find.text('Just now'), findsOneWidget);
    expect(await storedTriggers(tester), [Trigger.coffee]);

    await tester.disposeApp();
  });

  testWidgets('skipping the trigger still logs', (tester) async {
    await startPlan(today);
    await tester.pumpAppPastSplash(height: 2400);

    await tester.scrollAndTap(find.byTooltip('Log'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save without trigger'));
    await tester.pumpInSteps(const Duration(milliseconds: 900));

    expect(countText(tester), '1 / 9');
    expect(await storedTriggers(tester), [null]);

    await tester.disposeApp();
  });

  testWidgets('dismissing the trigger sheet logs nothing', (tester) async {
    await startPlan(today);
    await tester.pumpAppPastSplash(height: 2400);

    await tester.scrollAndTap(find.byTooltip('Log'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(200, 40));
    await tester.pumpAndSettle();

    expect(find.text('What triggered this one?'), findsNothing);
    expect(countText(tester), '0 / 9');
    expect(await storedTriggers(tester), isEmpty);

    await tester.disposeApp();
  });

  testWidgets('the first log offers to stop asking for triggers', (
    tester,
  ) async {
    await startPlan(today);
    await tester.pumpAppPastSplash(height: 2400);

    await tester.scrollAndTap(find.byTooltip('Log'));
    await tester.pumpAndSettle();
    expect(find.text('Ask every time'), findsOneWidget);

    await tester.tap(find.text('Ask every time'));
    await tester.pump();
    await tester.tap(find.text('Save without trigger'));
    await tester.pumpInSteps(const Duration(milliseconds: 900));
    expect(countText(tester), '1 / 9');

    // Asking is now off: the next log saves straight away.
    await tester.scrollAndTap(find.byTooltip('Log'));
    await tester.pumpInSteps(const Duration(milliseconds: 900));
    expect(find.text('What triggered this one?'), findsNothing);
    expect(countText(tester), '2 / 9');

    await tester.disposeApp();
  });

  testWidgets('later logs ask without the offer', (tester) async {
    await startPlan(today);
    await sl<SaveSettings>()(const AppSettings(triggerPromptIntroSeen: true));
    await tester.pumpAppPastSplash(height: 2400);

    await tester.scrollAndTap(find.byTooltip('Log'));
    await tester.pumpAndSettle();
    expect(find.text('What triggered this one?'), findsOneWidget);
    expect(find.text('Ask every time'), findsNothing);

    await tester.tap(find.text('Save without trigger'));
    await tester.pumpInSteps(const Duration(milliseconds: 900));
    expect(countText(tester), '1 / 9');

    await tester.disposeApp();
  });

  testWidgets('with asking turned off a log saves in one tap', (tester) async {
    await startPlan(today);
    await sl<SaveSettings>()(const AppSettings(askForTrigger: false));
    await tester.pumpAppPastSplash(height: 2400);

    await tester.scrollAndTap(find.byTooltip('Log'));
    await tester.pumpInSteps(const Duration(milliseconds: 900));

    expect(find.text('What triggered this one?'), findsNothing);
    expect(countText(tester), '1 / 9');
    expect(find.text('Logged at 3:42 PM'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('over the limit shows the overflow state', (tester) async {
    await startPlan(today, limit: 3);
    await logOn(DateTime(2026, 10, 16, 9), times: 5);
    await tester.pumpAppPastSplash(height: 2400);

    expect(countText(tester), '5 / 3');
    expect(find.text('Over limit'), findsOneWidget);
    expect(find.text('2 over limit'), findsOneWidget);
    expect(find.text('167% of daily limit'), findsOneWidget);
    expect(find.text('6h 38m ago'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('chart summarises the week and switches to month', (
    tester,
  ) async {
    await startPlan(LogicalDay(2026, 10, 14));
    await logOn(DateTime(2026, 10, 14, 9), times: 6);
    await logOn(DateTime(2026, 10, 15, 9), times: 11);
    await logOn(DateTime(2026, 10, 16, 9), times: 4);
    await tester.pumpAppPastSplash(height: 2400);

    await tester.ensureVisible(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('21 / 45 allowed'), findsOneWidget);
    expect(find.text('6 under'), findsOneWidget);
    expect(find.text('Avg 7.0/day'), findsOneWidget);
    expect(find.text('1 day over'), findsOneWidget);
    expect(find.text('2 days on track'), findsOneWidget);

    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    expect(find.text('Avg 7.0/day'), findsOneWidget);
    expect(find.text('Before plan'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('a past day on the ring has logs that can be deleted', (
    tester,
  ) async {
    await startPlan(LogicalDay(2026, 10, 14));
    await logOn(DateTime(2026, 10, 15, 9), times: 2);
    await tester.pumpAppPastSplash(height: 2400);

    await tapAndSettle(tester, find.byTooltip('Previous day'));

    expect(find.text('Thursday, Oct 15'), findsOneWidget);
    expect(countText(tester), '2 / 9');

    openLogs(
      tester.element(find.byType(HomePage)),
      LogsQuery(
        habitId: 1,
        from: LogicalDay(2026, 10, 15),
        to: LogicalDay(2026, 10, 15),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Logs'), findsOneWidget);
    expect(find.text('2 logged'), findsOneWidget);

    await tester.drag(find.byType(Dismissible).first, const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('1 logged'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('a missed log can be added from the logs page', (tester) async {
    await startPlan(LogicalDay(2026, 10, 14));
    await logOn(DateTime(2026, 10, 15, 9));
    await tester.pumpAppPastSplash(height: 2400);

    await tapAndSettle(tester, find.byTooltip('Previous day'));
    openLogs(
      tester.element(find.byType(HomePage)),
      LogsQuery(
        habitId: 1,
        from: LogicalDay(2026, 10, 15),
        to: LogicalDay(2026, 10, 15),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add a missed log'));
    await tester.pumpAndSettle();

    expect(find.text('12:00 PM'), findsOneWidget);
    await tester.scrollAndTap(find.text('Add log'));
    await tester.pumpAndSettle();

    expect(find.text('2 logged'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('stats reflect completed days and the price', (tester) async {
    await startPlan(LogicalDay(2026, 10, 14), priceCents: 1450);
    await logOn(DateTime(2026, 10, 14, 9), times: 6);
    await logOn(DateTime(2026, 10, 15, 9), times: 6);
    await tester.pumpAppPastSplash(height: 2400);

    await tester.ensureVisible(find.text('Money saved'));
    await tester.pumpAndSettle();
    expect(find.text('3 Days'), findsOneWidget);
    expect(find.text('↓ 33%'), findsOneWidget);
    expect(find.text(r'$4.35'), findsOneWidget);
    expect(find.text('6 cigs'), findsOneWidget);
    expect(find.text('D3'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('counts down to quit day on the last stage', (tester) async {
    await seedHabit(
      PlanDraft(
        startDay: today.addDays(-10),
        startLimit: 3,
        quitDay: today.addDays(3),
      ),
    );
    await tester.pumpAppPastSplash(height: 2400);

    expect(find.text('Quit day in 3d'), findsOneWidget);
    expect(find.text('Stage 3 of 3 · Daily limit: 1'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('after the quit date the limit is 0 and the day is smoke-free', (
    tester,
  ) async {
    await seedHabit(
      PlanDraft(
        startDay: today.addDays(-20),
        startLimit: 4,
        quitDay: today.addDays(-2),
      ),
    );
    await tester.pumpAppPastSplash(height: 2400);

    expect(countText(tester), '0 / 0');
    expect(find.text('Smoke-free day'), findsOneWidget);
    expect(find.text('Smoke-free since Oct 14'), findsOneWidget);
    expect(find.text('QUIT'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets("a vaping plan uses the habit's words and triggers", (
    tester,
  ) async {
    await startPlan(
      today,
      limit: 12,
      habit: Habit.vaping,
      reason: 'Breathe easier on my runs',
    );
    await tester.pumpAppPastSplash(height: 2400);

    expect(find.text('No sessions logged today. Nice start.'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('YOUR WHY'), findsOneWidget);
    expect(find.text('Breathe easier on my runs'), findsOneWidget);

    await tester.scrollAndTap(find.byTooltip('Log'));
    await tester.pumpAndSettle();
    expect(find.text('Work'), findsOneWidget);
    expect(find.text('Drinks'), findsNothing);

    await tester.tap(find.text('Work'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpInSteps(const Duration(milliseconds: 900));
    final logs = await storedLogs(tester);
    expect(logs.single.trigger, Trigger.work);
    expect(logs.single.habitId, 1);

    await tester.disposeApp();
  });

  testWidgets('a vape-free day after the quit date', (tester) async {
    await seedHabit(
      PlanDraft(
        startDay: today.addDays(-20),
        startLimit: 4,
        quitDay: today.addDays(-2),
      ),
      habit: Habit.vaping,
    );
    await tester.pumpAppPastSplash(height: 2400);

    expect(find.text('Vape-free day'), findsOneWidget);
    expect(find.text('Vape-free since Oct 14'), findsOneWidget);
    expect(find.text('Vape-free'), findsWidgets);

    await tester.disposeApp();
  });

  testWidgets('social media has no money tile', (tester) async {
    await startPlan(
      LogicalDay(2026, 10, 14),
      limit: 20,
      habit: Habit.socialMedia,
      priceCents: 500,
    );
    await logOn(DateTime(2026, 10, 14, 9), times: 15);
    await tester.pumpAppPastSplash(height: 2400);

    await tester.ensureVisible(find.text('Avoided'));
    await tester.pumpAndSettle();
    expect(find.text('Money saved'), findsNothing);
    expect(find.text('25 sessions'), findsOneWidget);
    expect(find.text('YOUR WHY'), findsNothing);

    await tester.disposeApp();
  });

  testWidgets("a stopped habit's logs don't count on Home", (tester) async {
    await startPlan(LogicalDay(2026, 10, 15), limit: 12, habit: Habit.vaping);
    final smoking = (await sl<AddHabit>()(
      const HabitDraft(habit: Habit.smoking),
    ) as Success<TrackedHabit>).value.id;
    await logOn(DateTime(2026, 10, 15, 9), times: 4);
    await logOn(DateTime(2026, 10, 16, 9), times: 2);
    await logOn(DateTime(2026, 10, 15, 10), times: 9, habitId: smoking);
    await logOn(DateTime(2026, 10, 16, 10), times: 5, habitId: smoking);
    await sl<ArchiveHabit>()(smoking);
    await tester.pumpAppPastSplash(height: 2400);

    expect(countText(tester), '2 / 12');

    await tester.ensureVisible(find.text('Avoided'));
    await tester.pumpAndSettle();
    expect(find.text('8 sessions'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('with two habits Home shows the oldest until it lists them', (
    tester,
  ) async {
    await startPlan(today, limit: 12, habit: Habit.vaping);
    await startPlan(today, limit: 4, habit: Habit.caffeine);
    await logOn(DateTime(2026, 10, 16, 9), times: 3);
    await tester.pumpAppPastSplash(height: 2400);

    expect(countText(tester), '3 / 12');
    expect(find.text('History'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('one habit shows the dashboard sections in order', (
    tester,
  ) async {
    await startPlan(LogicalDay(2026, 10, 14), reason: 'Breathe easier');
    await tester.pumpAppPastSplash(height: 2400);

    final sections = [
      find.text("Today's Consumption"),
      find.text('Streak'),
      find.textContaining('History'),
      find.text('Your plan'),
      find.text('YOUR WHY'),
      find.text("Today's logs"),
    ];
    final tops = [
      for (final section in sections) tester.getTopLeft(section.first).dy,
    ];
    expect(tops, orderedEquals([...tops]..sort()));
    expect(tops.toSet(), hasLength(sections.length));

    await tester.disposeApp();
  });

  testWidgets('your plan shows stage, next stage and quit date', (
    tester,
  ) async {
    await startPlan(LogicalDay(2026, 10, 14));
    await tester.pumpAppPastSplash(height: 2400);

    expect(find.text('Stage 1 · 9 a day (now)'), findsOneWidget);
    expect(find.text('Stage 2 · 8 a day'), findsOneWidget);
    expect(find.text('Starts Wed, Oct 21'), findsOneWidget);
    expect(find.text('Smoke-free from Dec 16'), findsOneWidget);
    expect(find.text('61 days to go'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets("today's logs shows 3 and a more link", (tester) async {
    await startPlan(today);
    await logOn(DateTime(2026, 10, 16, 9), times: 4);
    await tester.pumpAppPastSplash(height: 2400);

    expect(find.text('+1 more today · See all logs'), findsOneWidget);
    expect(find.text('9:03 AM'), findsOneWidget);
    expect(find.text('9:02 AM'), findsOneWidget);

    await tester.scrollAndTap(find.text('+1 more today · See all logs'));
    await tester.pumpAndSettle();

    expect(find.text('Logs'), findsOneWidget);
    expect(find.text('Today · Fri, Oct 16'), findsOneWidget);
    expect(find.byType(Dismissible), findsNWidgets(3));
    expect(find.text('Show 1 more'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets("today's logs says so when nothing is logged", (tester) async {
    await startPlan(today);
    await tester.pumpAppPastSplash(height: 2400);

    expect(find.text('Nothing logged today.'), findsOneWidget);
    expect(find.textContaining('more today'), findsNothing);

    await tester.disposeApp();
  });

  testWidgets('the habit route shows the dashboard with a back button', (
    tester,
  ) async {
    await startPlan(LogicalDay(2026, 10, 14));
    await tester.pumpAppPastSplash(height: 2400);

    unawaited(
      GoRouter.of(tester.element(find.byType(HomePage))).push('/habit/1'),
    );
    await tester.pumpInSteps(const Duration(milliseconds: 600));

    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.text('Your plan'), findsWidgets);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpInSteps(const Duration(milliseconds: 600));
    expect(find.byTooltip('Back'), findsNothing);

    await tester.disposeApp();
  });
}

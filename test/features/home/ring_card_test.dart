import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/theme/app_motion.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/status_badge.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/domain/repositories/habit_repository.dart';
import 'package:exhale/features/habit/domain/usecases/update_habit.dart';
import 'package:exhale/features/home/presentation/widgets/day_triggers.dart';
import 'package:exhale/features/home/presentation/widgets/quit_reached_card.dart';
import 'package:exhale/features/home/presentation/widgets/ring_card.dart';
import 'package:exhale/features/logs/presentation/logs_query.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/plan/presentation/pages/edit_plan_page.dart';
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

  Future<void> acknowledgeQuit(
    WidgetTester tester, {
    required DateTime at,
  }) async {
    final habits = await tester.runAsync(
      () => sl<HabitRepository>().watchActive().first,
    );
    await sl<UpdateHabit>()(
      habits!.single.copyWith(quitAcknowledgedAt: () => at),
    );
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

    openLogs(
      tester.element(find.byType(RingCard)),
      LogsQuery(
        habitId: 1,
        from: LogicalDay(2026, 10, 12),
        to: LogicalDay(2026, 10, 12),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add a missed log'));
    await tester.pumpAndSettle();
    await tester.scrollAndTap(find.text('Add log'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
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

  testWidgets('over the limit shows a coral badge and a supportive note', (
    tester,
  ) async {
    await startPlan(LogicalDay(2026, 10, 14), limit: 3);
    await logAt(DateTime(2026, 10, 16, 9), times: 5);
    await tester.pumpAppPastSplash(height: 2400);
    // The note waits for the ring to finish filling.
    await tester.pump(AppMotion.fill + const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    final badge = tester.widget<StatusBadge>(find.byType(StatusBadge));
    expect(badge.label, 'Over limit');
    expect(
      badge.colors.foreground,
      tester.element(find.byType(RingCard)).exhale.danger.foreground,
    );
    expect(find.text('2 over limit'), findsOneWidget);
    expect(
      find.text(
        'A harder day. Tomorrow starts fresh at 3, and your streak picks up '
        'again from there.',
      ),
      findsOneWidget,
    );

    await tester.disposeApp();
  });

  testWidgets('the first day shows a note and an empty ring', (tester) async {
    await seedHabit(
      PlanDraft(startDay: today, startLimit: 12, quitDay: today.addDays(84)),
      habit: Habit.vaping,
    );
    await tester.pumpAppPastSplash(height: 2400);

    expect(find.text('No sessions logged today. Nice start.'), findsOneWidget);
    expect(countText(tester), '0 / 12');
    expect(
      find.text("Today's triggers show here once you log."),
      findsOneWidget,
    );

    await tester.disposeApp();
  });

  group('quit reached', () {
    Future<int> quitDaysAgo(int days, {Habit habit = Habit.vaping}) =>
        seedHabit(
          PlanDraft(
            startDay: today.addDays(-20),
            startLimit: 4,
            quitDay: today.addDays(-days),
          ),
          habit: habit,
        );

    Finder inQuitCard(String label) => find.descendant(
      of: find.byType(QuitReachedCard),
      matching: find.text(label),
    );

    testWidgets('shows a full success ring, the free days and the card', (
      tester,
    ) async {
      await quitDaysAgo(2);
      await tester.pumpAppPastSplash(height: 2400);

      final context = tester.element(find.byType(RingCard));
      final success = context.exhale.success;
      expect(countText(tester), '3');
      expect(find.text('days vape-free'), findsOneWidget);
      expect(find.text('Nothing logged today'), findsOneWidget);
      expect(find.text('Vape-free so far today.'), findsNothing);
      expect(
        tester.renderObject(
          find
              .ancestor(
                of: find.byKey(const Key('day-count')),
                matching: find.byType(CustomPaint),
              )
              .first,
        ),
        paints
          ..arc()
          ..arc(color: success.solid),
      );
      expect(inQuitCard('You reached your quit date'), findsOneWidget);
      expect(
        inQuitCard(
          "Your limit stays at zero. A slip still gets logged and doesn't "
          'reset your plan.',
        ),
        findsOneWidget,
      );
      expect(inQuitCard('Keep at zero'), findsOneWidget);
      expect(inQuitCard('New goal'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('QUIT')).style?.color,
        success.foreground,
      );

      await tester.disposeApp();
    });

    testWidgets('the quit day itself counts as one day', (tester) async {
      await quitDaysAgo(0);
      await tester.pumpAppPastSplash(height: 2400);

      expect(countText(tester), '1');
      expect(find.text('day vape-free'), findsOneWidget);
      expect(find.byType(QuitReachedCard), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets('a habit with no free word counts days at zero', (
      tester,
    ) async {
      await quitDaysAgo(2, habit: Habit.socialMedia);
      await tester.pumpAppPastSplash(height: 2400);

      expect(find.text('days at zero'), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets('a slip restarts the count', (tester) async {
      await quitDaysAgo(5);
      await logAt(DateTime(2026, 10, 15, 9));
      await tester.pumpAppPastSplash(height: 2400);

      expect(countText(tester), '1');
      expect(find.text('day vape-free'), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets('a slip today shows over the limit and keeps the card', (
      tester,
    ) async {
      await quitDaysAgo(2);
      await logAt(DateTime(2026, 10, 16, 9));
      await tester.pumpAppPastSplash(height: 2400);

      expect(countText(tester), '1 / 0');
      expect(find.text('1 over limit'), findsOneWidget);
      expect(find.text('day vape-free'), findsNothing);
      expect(find.byType(QuitReachedCard), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets('a past day keeps its count and has no card', (tester) async {
      await quitDaysAgo(5);
      await tester.pumpAppPastSplash(height: 2400);

      await tapAndSettle(tester, find.byTooltip('Previous day'));

      expect(countText(tester), '0 / 0');
      expect(find.text('Vape-free day'), findsOneWidget);
      expect(find.byType(QuitReachedCard), findsNothing);

      await tester.disposeApp();
    });

    testWidgets('Keep at zero hides the card and is stored', (tester) async {
      await quitDaysAgo(2);
      await tester.pumpAppPastSplash(height: 2400);

      await tapAndSettle(tester, inQuitCard('Keep at zero'));
      await tester.pumpInSteps(const Duration(milliseconds: 900));

      expect(find.byType(QuitReachedCard), findsNothing);
      expect(find.text('days vape-free'), findsOneWidget);
      final habits = await tester.runAsync(
        () => sl<HabitRepository>().watchActive().first,
      );
      expect(habits!.single.quitAcknowledgedAt, now);

      await tester.disposeApp();
    });

    testWidgets('a stored Keep at zero stays hidden', (tester) async {
      await quitDaysAgo(2);
      await acknowledgeQuit(tester, at: now);
      await tester.pumpAppPastSplash(height: 2400);

      expect(find.byType(QuitReachedCard), findsNothing);

      await tester.disposeApp();
    });

    testWidgets('Keep at zero on an older goal does not hide a new quit date', (
      tester,
    ) async {
      await quitDaysAgo(2);
      await acknowledgeQuit(tester, at: now.subtract(const Duration(days: 3)));
      await tester.pumpAppPastSplash(height: 2400);

      expect(find.byType(QuitReachedCard), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets('New goal opens Edit plan', (tester) async {
      await quitDaysAgo(2);
      await tester.pumpAppPastSplash(height: 2400);

      await tapAndSettle(tester, inQuitCard('New goal'));

      expect(find.byType(EditPlanPage), findsOneWidget);

      await tester.disposeApp();
    });

    testWidgets('before the quit date there is no card', (tester) async {
      await startPlan(LogicalDay(2026, 10, 14));
      await tester.pumpAppPastSplash(height: 2400);

      expect(find.byType(QuitReachedCard), findsNothing);

      await tester.disposeApp();
    });
  });
}

import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/home/presentation/pages/habit_details_page.dart';
import 'package:exhale/features/home/presentation/widgets/habit_dashboard.dart';
import 'package:exhale/features/home/presentation/widgets/habit_list_home.dart';
import 'package:exhale/features/home/presentation/widgets/habit_summary_card.dart';
import 'package:exhale/features/home/presentation/widgets/recent_logs_card.dart';
import 'package:exhale/features/logs/presentation/pages/logs_page.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/repositories/settings_repository.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:exhale/features/tracking/domain/repositories/habit_log_repository.dart';
import 'package:exhale/features/tracking/presentation/trigger_ui.dart';
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

  Future<int> seed(
    Habit habit, {
    int limit = 9,
    int daysAgo = 0,
    int? priceCents,
  }) {
    final start = today.addDays(-daysAgo);
    return seedHabit(
      PlanDraft(
        startDay: start,
        startLimit: limit,
        quitDay: start.addDays(limit * 7),
      ),
      habit: habit,
      priceCents: priceCents,
    );
  }

  Future<void> log(
    int habitId,
    DateTime at, {
    int times = 1,
    Trigger? trigger,
  }) async {
    for (var i = 0; i < times; i++) {
      await sl<HabitLogRepository>().addLog(
        habitId: habitId,
        loggedAt: at.add(Duration(minutes: i)),
        trigger: trigger,
      );
    }
  }

  Finder inCard(String habitName, Finder finder) => find.descendant(
    of: find.ancestor(
      of: find.text(habitName),
      matching: find.byType(HabitSummaryCard),
    ),
    matching: finder,
  );

  testWidgets('one habit keeps the dashboard', (tester) async {
    await seed(Habit.smoking);
    await tester.pumpAppPastSplash(height: 2400);

    expect(find.byType(HabitDashboard), findsOneWidget);
    expect(find.byType(HabitListHome), findsNothing);
    await tester.disposeApp();
  });

  testWidgets('two habits list one card each, oldest first', (tester) async {
    await seed(Habit.smoking);
    await seed(Habit.vaping);
    await tester.pumpAppPastSplash(height: 2400);

    expect(find.byType(HabitDashboard), findsNothing);
    expect(find.text('Good afternoon'), findsOneWidget);
    expect(find.text("Today's habits"), findsOneWidget);
    expect(find.text('2 active'), findsOneWidget);
    expect(find.byType(HabitSummaryCard), findsNWidgets(2));
    expect(
      tester.getTopLeft(find.text('Smoking')).dy,
      lessThan(tester.getTopLeft(find.text('Vaping')).dy),
    );
    await tester.disposeApp();
  });

  testWidgets('cards show status and progress', (tester) async {
    final smoking = await seed(Habit.smoking);
    final vaping = await seed(Habit.vaping, limit: 3);
    final alcohol = await seed(Habit.alcohol, limit: 2);
    await log(smoking, DateTime(2026, 10, 16, 13), times: 4);
    await log(vaping, DateTime(2026, 10, 16, 9), times: 3);
    await log(alcohol, DateTime(2026, 10, 16, 9), times: 4);
    await tester.pumpAppPastSplash(height: 2400);

    expect(inCard('Smoking', find.text('On track')), findsOneWidget);
    expect(inCard('Smoking', find.text('4 / 9 cigarettes')), findsOneWidget);
    expect(inCard('Smoking', find.text('5 left today')), findsOneWidget);
    expect(
      inCard('Smoking', find.text('Stage 1 of 9 · Daily limit: 9')),
      findsOneWidget,
    );
    expect(inCard('Smoking', find.text('Last: 2h 39m ago')), findsOneWidget);
    expect(inCard('Smoking', find.text('Drops to 8 in 7d')), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      inCard('Smoking', find.byType(LinearProgressIndicator)),
    );
    expect(bar.value, closeTo(4 / 9, 0.001));

    expect(inCard('Vaping', find.text('At limit')), findsOneWidget);
    expect(inCard('Vaping', find.text('Limit reached')), findsOneWidget);

    expect(inCard('Alcohol', find.text('Over limit')), findsOneWidget);
    expect(inCard('Alcohol', find.text('2 over limit')), findsOneWidget);
    await tester.disposeApp();
  });

  testWidgets('a card without logs says so; after the quit date it is free', (
    tester,
  ) async {
    await seed(Habit.smoking);
    await seed(Habit.vaping, limit: 1, daysAgo: 30);
    await tester.pumpAppPastSplash(height: 2400);

    expect(inCard('Smoking', find.text('No logs yet')), findsOneWidget);
    expect(inCard('Vaping', find.text('Vape-free')), findsOneWidget);
    expect(inCard('Vaping', find.text('Keep it going')), findsOneWidget);
    await tester.disposeApp();
  });

  testWidgets('a card opens its habit with the pace line under the ring', (
    tester,
  ) async {
    await seed(Habit.smoking);
    await seed(Habit.vaping);
    final repository = sl<SettingsRepository>();
    final settings = await repository.get() as Success<AppSettings>;
    await repository.save(
      settings.value.copyWith(wakeMinute: () => 450, bedMinute: () => 1410),
    );
    await tester.pumpAppPastSplash(height: 2400);

    await tester.tap(find.text('Vaping'));
    await tester.pumpAndSettle();

    expect(find.byType(HabitDetailsPage), findsOneWidget);
    expect(find.textContaining('until bed'), findsOneWidget);
    await tester.disposeApp();
  });

  testWidgets('combined impact sums money and keeps units apart', (
    tester,
  ) async {
    final gum = await seed(
      Habit.custom(name: 'Gum', unit: 'piece'),
      limit: 5,
      daysAgo: 2,
      priceCents: 100,
    );
    final soda = await seed(
      Habit.custom(name: 'Soda', unit: 'can'),
      limit: 4,
      daysAgo: 2,
      priceCents: 200,
    );
    await log(gum, DateTime(2026, 10, 15, 9), times: 3);
    await log(soda, DateTime(2026, 10, 15, 9));
    await tester.pumpAppPastSplash(height: 2400);

    expect(find.text('Combined impact'), findsOneWidget);
    expect(find.text(r'$21.00'), findsOneWidget);
    expect(find.text('Both habits, since day 1'), findsOneWidget);
    expect(find.text('Pieces avoided'), findsOneWidget);
    expect(find.text('vs 5/day start'), findsOneWidget);
    expect(find.text('Cans avoided'), findsOneWidget);
    expect(find.text('vs 4/day start'), findsOneWidget);
    expect(find.text('7'), findsNWidgets(2));
    expect(find.text('All on track'), findsOneWidget);
    expect(find.text('3 days'), findsOneWidget);
    expect(find.text('Every habit within limit'), findsOneWidget);
    expect(find.text('Healthy trajectory'), findsOneWidget);
    await tester.disposeApp();
  });

  testWidgets('money without any price shows a dash', (tester) async {
    await seed(Habit.smoking);
    await seed(Habit.vaping);
    await tester.pumpAppPastSplash(height: 2400);

    expect(find.text('Money saved'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    expect(find.text('No price set'), findsOneWidget);
    await tester.disposeApp();
  });

  testWidgets('a habit over today breaks the combined streak', (tester) async {
    await seed(Habit.smoking, daysAgo: 2);
    final vaping = await seed(Habit.vaping, limit: 1, daysAgo: 2);
    await log(vaping, DateTime(2026, 10, 16, 9), times: 3);
    await tester.pumpAppPastSplash(height: 2400);

    expect(find.text('0 days'), findsOneWidget);
    expect(find.text('Healthy trajectory'), findsNothing);
    await tester.disposeApp();
  });

  testWidgets('recent logs mix habits newest first', (tester) async {
    final smoking = await seed(Habit.smoking, daysAgo: 2);
    final vaping = await seed(Habit.vaping, daysAgo: 2);
    await log(smoking, DateTime(2026, 10, 15, 23, 10), trigger: Trigger.social);
    await log(vaping, DateTime(2026, 10, 16, 15, 30), trigger: Trigger.stress);
    await log(smoking, DateTime(2026, 10, 16, 14, 5));
    await tester.pumpAppPastSplash(height: 2400);

    final card = find.byType(RecentLogsCard);
    Finder inRecent(String text) =>
        find.descendant(of: card, matching: find.text(text));
    expect(find.text('Recent logs'), findsOneWidget);
    expect(inRecent('Vaping'), findsOneWidget);
    expect(inRecent('Smoking'), findsNWidgets(2));
    expect(inRecent('No trigger'), findsOneWidget);
    expect(inRecent(Trigger.stress.label), findsOneWidget);
    final top = tester.getTopLeft(inRecent('Today, 3:30 PM')).dy;
    final middle = tester.getTopLeft(inRecent('Today, 2:05 PM')).dy;
    final bottom = tester.getTopLeft(inRecent('Yesterday, 11:10 PM')).dy;
    expect(top, lessThan(middle));
    expect(middle, lessThan(bottom));
    await tester.disposeApp();
  });

  testWidgets('recent logs stop at six and open Logs', (tester) async {
    final smoking = await seed(Habit.smoking);
    await seed(Habit.vaping);
    await log(smoking, DateTime(2026, 10, 16, 9), times: 8);
    await tester.pumpAppPastSplash(height: 2400);

    expect(
      find.descendant(
        of: find.byType(RecentLogsCard),
        matching: find.textContaining('Today, '),
      ),
      findsNWidgets(6),
    );

    await tester.tap(find.text('See all logs'));
    await tester.pumpAndSettle();

    expect(find.byType(LogsPage), findsOneWidget);
    await tester.disposeApp();
  });

  testWidgets('a recent log opens in the editor under its own habit', (
    tester,
  ) async {
    await seed(Habit.smoking);
    final vaping = await seed(Habit.vaping);
    await log(vaping, DateTime(2026, 10, 16, 15));
    await tester.pumpAppPastSplash(height: 2400);

    await tester.tap(find.text('Today, 3:00 PM'));
    await tester.pumpAndSettle();

    expect(find.text('Edit log'), findsOneWidget);
    expect(find.text('Vaping · Fri, Oct 16'), findsOneWidget);
    await tester.disposeApp();
  });
}

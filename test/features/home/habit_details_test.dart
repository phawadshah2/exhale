import 'dart:async';

import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:exhale/features/habit/domain/repositories/habit_repository.dart';
import 'package:exhale/features/habit/domain/usecases/archive_habit.dart';
import 'package:exhale/features/home/presentation/pages/habit_details_page.dart';
import 'package:exhale/features/home/presentation/pages/home_page.dart';
import 'package:exhale/features/home/presentation/widgets/habit_dashboard.dart';
import 'package:exhale/features/home/presentation/widgets/habit_list_home.dart';
import 'package:exhale/features/logs/presentation/logs_query.dart';
import 'package:exhale/features/logs/presentation/pages/logs_page.dart';
import 'package:exhale/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/plan/presentation/pages/edit_plan_page.dart';
import 'package:exhale/features/tracking/domain/repositories/habit_log_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/pump_app.dart';

void main() {
  final today = LogicalDay(2026, 10, 16);

  setUp(
    () => setUpTestDependencies(FixedClock(DateTime(2026, 10, 16, 15, 42))),
  );
  tearDown(InjectionContainer.reset);

  Future<int> seed(Habit habit, {int limit = 9}) => seedHabit(
    PlanDraft(
      startDay: today,
      startLimit: limit,
      quitDay: today.addDays(limit * 7),
    ),
    habit: habit,
  );

  void push(WidgetTester tester, String location) => unawaited(
    GoRouter.of(tester.element(find.byType(HomePage))).push<void>(location),
  );

  String dayCount(WidgetTester tester) => tester
      .widget<Text>(find.byKey(const Key('day-count')))
      .textSpan!
      .toPlainText();

  Future<List<TrackedHabit>> active(WidgetTester tester) async {
    final result = await tester.runAsync(sl<HabitRepository>().getActive);
    return (result! as Success<List<TrackedHabit>>).value;
  }

  Future<void> settleStreams(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> stopTracking(WidgetTester tester, String name) async {
    await tester.tap(find.byTooltip('Edit plan'));
    await tester.pumpAndSettle();
    final button = find.text('Stop tracking $name');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  group('switcher', () {
    testWidgets('the pill names the habit and lists every active one', (
      tester,
    ) async {
      await seed(Habit.smoking);
      final vaping = await seed(Habit.vaping);
      await tester.pumpAppPastSplash(height: 2400);
      push(tester, AppRoutes.habitFor(vaping));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Switch habit'));
      await tester.pumpAndSettle();

      expect(find.text('Switch habit'), findsOneWidget);
      expect(find.text('Smoking'), findsOneWidget);
      expect(find.text('Vaping'), findsNWidgets(2));

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      await tester.disposeApp();
    });

    testWidgets('switcher changes the shown habit', (tester) async {
      final smoking = await seed(Habit.smoking);
      final vaping = await seed(Habit.vaping, limit: 5);
      await sl<HabitLogRepository>().addLog(
        habitId: vaping,
        loggedAt: DateTime(2026, 10, 16, 9),
      );
      await tester.pumpAppPastSplash(height: 2400);
      push(tester, AppRoutes.habitFor(vaping));
      await tester.pumpAndSettle();
      expect(dayCount(tester), '1 / 5');

      await tester.tap(find.byTooltip('Switch habit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Smoking'));
      await tester.pumpAndSettle();

      expect(dayCount(tester), '0 / 9');
      expect(
        tester.widget<HabitDetailsPage>(find.byType(HabitDetailsPage)).habitId,
        smoking,
      );

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(HabitListHome), findsOneWidget);
      await tester.disposeApp();
    });

    testWidgets('with one habit there is nothing to switch to', (tester) async {
      final smoking = await seed(Habit.smoking);
      await tester.pumpAppPastSplash(height: 2400);
      push(tester, AppRoutes.habitFor(smoking));
      await tester.pumpAndSettle();

      expect(find.text('Smoking'), findsOneWidget);
      expect(find.byTooltip('Switch habit'), findsNothing);
      await tester.disposeApp();
    });
  });

  group('stop tracking', () {
    testWidgets('asks first, and cancelling keeps the habit', (tester) async {
      final smoking = await seed(Habit.smoking);
      await seed(Habit.vaping);
      await tester.pumpAppPastSplash(height: 2400);
      push(tester, AppRoutes.habitFor(smoking));
      await tester.pumpAndSettle();

      await stopTracking(tester, 'Smoking');

      expect(find.text('Stop tracking Smoking?'), findsOneWidget);
      expect(
        find.text('Its logs are kept. You can add it again later.'),
        findsWidgets,
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(EditPlanPage), findsOneWidget);
      expect(await active(tester), hasLength(2));
      await tester.disposeApp();
    });

    testWidgets(
      "stopping tracking returns Home and shows the remaining habit's "
      'dashboard',
      (tester) async {
        final smoking = await seed(Habit.smoking);
        final vaping = await seed(Habit.vaping, limit: 5);
        await sl<HabitLogRepository>().addLog(
          habitId: smoking,
          loggedAt: DateTime(2026, 10, 16, 9),
        );
        await tester.pumpAppPastSplash(height: 2400);
        push(tester, AppRoutes.habitFor(smoking));
        await tester.pumpAndSettle();

        await stopTracking(tester, 'Smoking');
        await tester.tap(find.text('Stop tracking'));
        await tester.pumpAndSettle();
        await settleStreams(tester);

        expect(find.byType(EditPlanPage), findsNothing);
        expect(find.byType(HabitDetailsPage), findsNothing);
        expect(find.byType(HabitDashboard), findsOneWidget);
        expect(find.byType(HabitListHome), findsNothing);
        expect(dayCount(tester), '0 / 5');
        expect((await active(tester)).map((h) => h.id), [vaping]);
        expect(tester.takeException(), isNull);
        await tester.disposeApp();
      },
    );

    testWidgets('its logs are kept and it can be added again', (tester) async {
      final smoking = await seed(Habit.smoking);
      await seed(Habit.vaping);
      await sl<HabitLogRepository>().addLog(
        habitId: smoking,
        loggedAt: DateTime(2026, 10, 16, 9),
      );
      await sl<ArchiveHabit>()(smoking);
      await tester.pumpAppPastSplash(height: 2400);

      final logs = await tester.runAsync(
        () => sl<HabitLogRepository>()
            .watchLogs(
              habitId: smoking,
              from: DateTime(2026, 10, 16),
              to: DateTime(2026, 10, 17),
            )
            .first,
      );
      expect(logs, hasLength(1));

      await tester.longPress(find.byTooltip('Log'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add a habit'));
      await tester.pumpAndSettle();

      expect(find.text('TRACKING'), findsOneWidget);
      await tester.disposeApp();
    });

    testWidgets('stopping the last habit starts onboarding', (tester) async {
      final smoking = await seed(Habit.smoking);
      await tester.pumpAppPastSplash(height: 2400);
      push(tester, AppRoutes.habitFor(smoking));
      await tester.pumpAndSettle();

      await stopTracking(tester, 'Smoking');
      await tester.tap(find.text('Stop tracking'));
      await tester.pumpAndSettle();
      await settleStreams(tester);

      expect(find.byType(OnboardingPage), findsOneWidget);
      expect(find.byType(HabitDashboard), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.disposeApp();
    });
  });

  group('a habit archived while open', () {
    testWidgets("an archived habit's open Logs filter returns Home without "
        'error', (tester) async {
      await seed(Habit.smoking);
      final vaping = await seed(Habit.vaping);
      await tester.pumpAppPastSplash(height: 2400);
      push(tester, LogsQuery(habitId: vaping).toUri().toString());
      await tester.pumpAndSettle();
      expect(find.byType(LogsPage), findsOneWidget);

      await tester.runAsync(() => sl<ArchiveHabit>()(vaping));
      await settleStreams(tester);

      expect(find.byType(LogsPage), findsNothing);
      expect(find.byType(HabitDashboard), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.disposeApp();
    });

    testWidgets('its open dashboard returns Home without error', (
      tester,
    ) async {
      await seed(Habit.smoking);
      final vaping = await seed(Habit.vaping);
      await tester.pumpAppPastSplash(height: 2400);
      push(tester, AppRoutes.habitFor(vaping));
      await tester.pumpAndSettle();

      await tester.runAsync(() => sl<ArchiveHabit>()(vaping));
      await settleStreams(tester);

      expect(find.byType(HabitDetailsPage), findsNothing);
      expect(find.byType(HabitDashboard), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.disposeApp();
    });

    testWidgets('a link to an archived habit returns Home', (tester) async {
      await seed(Habit.smoking);
      final vaping = await seed(Habit.vaping);
      await sl<ArchiveHabit>()(vaping);
      await tester.pumpAppPastSplash(height: 2400);

      push(tester, AppRoutes.habitFor(vaping));
      await tester.pumpAndSettle();
      await settleStreams(tester);

      expect(find.byType(HabitDetailsPage), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.disposeApp();
    });
  });
}

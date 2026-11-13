import 'dart:async';

import 'package:exhale/app/app.dart';
import 'package:exhale/app/router/app_router.dart';
import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/home/presentation/pages/home_page.dart';
import 'package:exhale/features/logs/presentation/pages/logs_page.dart';
import 'package:exhale/features/onboarding/presentation/pages/welcome_back_page.dart';
import 'package:exhale/features/paywall/data/fake/fake_store_repository.dart';
import 'package:exhale/features/paywall/domain/entities/access.dart';
import 'package:exhale/features/paywall/domain/entities/plan_kind.dart';
import 'package:exhale/features/paywall/presentation/pages/locked_page.dart';
import 'package:exhale/features/paywall/presentation/pages/paywall_page.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/domain/repositories/plan_repository.dart';
import 'package:exhale/features/tracking/domain/repositories/habit_log_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixed_clock.dart';
import '../helpers/onboarding.dart';
import '../helpers/pump_app.dart';

void main() {
  final now = DateTime(2026, 11, 13, 15);
  late FakeStoreRepository store;

  const lifetime = Entitled(
    plan: PlanKind.lifetime,
    expiresAt: null,
    inTrial: false,
  );
  final lapsed = Lapsed(plan: PlanKind.annual, endedAt: now);

  setUp(() async {
    store = FakeStoreRepository(now: () => now);
    await setUpTestDependencies(FixedClock(now), store: store);
  });

  tearDown(InjectionContainer.reset);

  Future<int> seed({required LogicalDay startDay}) => seedHabit(
    PlanDraft(startDay: startDay, startLimit: 5, quitDay: startDay.addDays(30)),
  );

  Future<void> addLog(int habitId) async {
    final result = await sl<HabitLogRepository>().addLog(
      habitId: habitId,
      loggedAt: now.subtract(const Duration(days: 2)),
    );
    expect(result, isA<Success<Object>>());
  }

  Future<PlanHistory?> history(int habitId) async =>
      (await sl<PlanRepository>().getHistory(
        habitId,
      ) as Success<PlanHistory?>).value;

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();
  }

  testWidgets('a plan with logs, never paid, opens the paywall and keeps '
      'its dates', (tester) async {
    final habitId = await seed(startDay: LogicalDay(2026, 11, 1));
    await addLog(habitId);
    final before = await history(habitId);

    await tester.pumpAppPastSplash(height: 2400);

    expect(find.byKey(PaywallPage.pageKey), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
    final after = await tester.runAsync(() => history(habitId));
    expect(after!.plans, before!.plans);

    await tester.disposeApp();
  });

  testWidgets('a plan with no logs, never paid, opens welcome back', (
    tester,
  ) async {
    await seed(startDay: LogicalDay(2026, 11, 1));
    // The plan step's button loops while animations are on.
    reduceMotion(tester);

    await tester.pumpAppPastSplash(height: 2400);

    expect(find.byKey(WelcomeBackPage.pageKey), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('a lapsed access opens locked', (tester) async {
    store.access = lapsed;
    await seed(startDay: LogicalDay(2026, 11, 1));

    await tester.pumpAppPastSplash(height: 2400);

    expect(find.byKey(LockedPage.pageKey), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('on home, a store change to lapsed opens locked', (tester) async {
    store.access = lifetime;
    await seed(startDay: LogicalDay(2026, 11, 13));
    await tester.pumpAppPastSplash(height: 2400);
    expect(find.byType(HomePage), findsOneWidget);

    store
      ..access = lapsed
      ..emitChange();
    await settle(tester);

    expect(find.byKey(LockedPage.pageKey), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);

    await tester.disposeApp();
  });

  testWidgets('on a pushed Logs page, a resume with lapsed opens locked', (
    tester,
  ) async {
    store.access = lifetime;
    await seed(startDay: LogicalDay(2026, 11, 13));
    await tester.pumpAppPastSplash(height: 2400);
    final scope = ProviderScope.containerOf(
      tester.element(find.byType(ExhaleApp)),
    );
    unawaited(scope.read(routerProvider).push<void>(AppRoutes.logs));
    await tester.pumpAndSettle();
    expect(find.byType(LogsPage), findsOneWidget);

    store.access = lapsed;
    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
      ..handleAppLifecycleStateChanged(AppLifecycleState.paused)
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await settle(tester);

    expect(find.byKey(LockedPage.pageKey), findsOneWidget);
    expect(find.byType(LogsPage), findsNothing);

    await tester.disposeApp();
  });

  testWidgets('on locked, a store change to entitled opens home', (
    tester,
  ) async {
    store.access = lapsed;
    await seed(startDay: LogicalDay(2026, 11, 1));
    await tester.pumpAppPastSplash(height: 2400);
    expect(find.byKey(LockedPage.pageKey), findsOneWidget);

    store
      ..access = lifetime
      ..emitChange();
    await settle(tester);

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byKey(LockedPage.pageKey), findsNothing);

    await tester.disposeApp();
  });
}

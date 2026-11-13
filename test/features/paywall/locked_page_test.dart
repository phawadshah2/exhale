import 'dart:async';

import 'package:exhale/app/app.dart';
import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/platform/native_ui.dart';
import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/home/presentation/pages/home_page.dart';
import 'package:exhale/features/home/presentation/providers/home_providers.dart';
import 'package:exhale/features/paywall/data/fake/fake_store_repository.dart';
import 'package:exhale/features/paywall/domain/entities/access.dart';
import 'package:exhale/features/paywall/domain/entities/plan_kind.dart';
import 'package:exhale/features/paywall/presentation/pages/locked_page.dart';
import 'package:exhale/features/paywall/presentation/pages/paywall_page.dart';
import 'package:exhale/features/paywall/presentation/paywall_copy.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/plan/domain/repositories/plan_repository.dart';
import 'package:exhale/features/tracking/domain/entities/home_stats.dart';
import 'package:exhale/features/tracking/domain/repositories/habit_log_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/pump_app.dart';

void main() {
  final now = DateTime(2026, 12, 5, 15);
  final started = LogicalDay(2026, 11, 15);
  final endedAt = DateTime(2026, 12, 3, 10);
  late FakeStoreRepository store;
  late int habitId;

  setUp(() async {
    store = FakeStoreRepository(
      access: Lapsed(plan: PlanKind.annual, endedAt: endedAt),
      now: () => now,
    );
    await setUpTestDependencies(FixedClock(now), store: store);
  });

  tearDown(InjectionContainer.reset);

  /// Vaping at 12 a day on an 8-week plan, day 21 today, 5 logged on each
  /// earlier day. A pod at 15.00 for 20 sessions unless [priceCents] is null.
  Future<void> seed({int? priceCents = 1500}) async {
    habitId = await seedHabit(
      PlanDraft(
        startDay: started,
        startLimit: 12,
        quitDay: started.addDays(56),
      ),
      habit: Habit.vaping,
      priceCents: priceCents,
    );
    for (var day = 0; day < 20; day++) {
      final date = started.addDays(day).toLocalDate();
      for (var i = 0; i < 5; i++) {
        final result = await sl<HabitLogRepository>().addLog(
          habitId: habitId,
          loggedAt: DateTime(date.year, date.month, date.day, 12, i),
        );
        expect(result, isA<Success<Object>>());
      }
    }
  }

  Future<PlanHistory?> history() async =>
      (await sl<PlanRepository>().getHistory(
        habitId,
      ) as Success<PlanHistory?>).value;

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();
  }

  Future<void> open(
    WidgetTester tester, {
    List<Override> overrides = const [],
  }) async {
    await tester.pumpAppPastSplash(overrides: overrides);
    await settle(tester);
    expect(find.byKey(LockedPage.pageKey), findsOneWidget);
  }

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(ExhaleApp)));

  Future<HomeStats> stats(WidgetTester tester) async {
    final value = await tester.runAsync(
      () => container(tester).read(habitStatsProvider(habitId).future),
    );
    return value!;
  }

  ReductionPlan plan() => ReductionPlan(
    startDay: started,
    startLimit: 12,
    quitDay: started.addDays(56),
  );

  testWidgets('says the plan ended and shows the progress', (tester) async {
    await seed();
    await open(tester);
    final homeStats = await stats(tester);
    final stage = plan().stageOn(LogicalDay(2026, 12, 5))!;

    expect(find.text(PaywallCopy.lockedTitle), findsOneWidget);
    expect(
      find.text(
        'Your Annual plan ended on '
        '${AppFormat.monthDay(LogicalDay(2026, 12, 3))}. '
        'Everything here comes back the moment you do.',
      ),
      findsOneWidget,
    );
    expect(homeStats.dayNumber, 21);
    expect(homeStats.avoided, greaterThan(0));
    final money = AppFormat.money(homeStats.moneySavedCents!, symbol: r'$');
    expect(
      find.text(
        '21 days on plan · ${homeStats.avoided} sessions avoided\n'
        '$money saved · stage ${stage.number} of ${plan().stageCount}',
      ),
      findsOneWidget,
    );

    await tester.disposeApp();
  });

  testWidgets('without a price the money part is left out', (tester) async {
    await seed(priceCents: null);
    await open(tester);
    final homeStats = await stats(tester);
    final stage = plan().stageOn(LogicalDay(2026, 12, 5))!;

    expect(
      find.text(
        '21 days on plan · ${homeStats.avoided} sessions avoided\n'
        'stage ${stage.number} of ${plan().stageCount}',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('saved ·'), findsNothing);

    await tester.disposeApp();
  });

  testWidgets('with no end date the plan has ended', (tester) async {
    store.access = const Lapsed(plan: PlanKind.lifetime, endedAt: null);
    await seed();
    await open(tester);

    expect(
      find.text(
        'Your Lifetime plan has ended. '
        'Everything here comes back the moment you do.',
      ),
      findsOneWidget,
    );

    await tester.disposeApp();
  });

  testWidgets('Home is behind the sheet and cannot be tapped', (tester) async {
    await seed();
    await open(tester);

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byIcon(AppIcons.add), findsNothing);
    final homeTexts = find.descendant(
      of: find.byType(HomePage),
      matching: find.byType(Text),
    );
    expect(homeTexts, findsWidgets);
    expect(homeTexts.hitTestable(), findsNothing);

    await tester.disposeApp();
  });

  testWidgets('See offers opens the paywall with a back chevron', (
    tester,
  ) async {
    await seed();
    await open(tester);

    await tester.tap(find.text(PaywallCopy.seeOffers));
    await settle(tester);

    expect(find.byKey(PaywallPage.pageKey), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(PaywallPage.pageKey),
        matching: find.byIcon(AppIcons.back),
      ),
      findsOneWidget,
    );

    await tester.disposeApp();
  });

  testWidgets('Restore finding a purchase opens Home with the same plan', (
    tester,
  ) async {
    store.restoreFinds = const Entitled(
      plan: PlanKind.lifetime,
      expiresAt: null,
      inTrial: false,
    );
    await seed();
    final before = await history();
    await open(tester);

    await tester.tap(find.text(PaywallCopy.restorePurchases));
    await settle(tester);

    expect(store.restoreCalls, 1);
    expect(find.byKey(LockedPage.pageKey), findsNothing);
    expect(find.byType(HomePage), findsOneWidget);
    final after = await tester.runAsync(history);
    expect(after!.plans, before!.plans);

    await tester.disposeApp();
  });

  testWidgets('Restore finding nothing says so', (tester) async {
    await seed();
    await open(tester);

    await tester.tap(find.text(PaywallCopy.restorePurchases));
    await tester.runAsync(pumpEventQueue);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(PaywallCopy.noPurchases), findsOneWidget);
    expect(find.byKey(LockedPage.pageKey), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('blurred with glass on', (tester) async {
    await seed();
    await open(tester);

    expect(
      find.descendant(
        of: find.byKey(LockedPage.pageKey),
        matching: find.byType(ImageFiltered),
      ),
      findsOneWidget,
    );

    await tester.disposeApp();
  });

  testWidgets('Reduce Transparency leaves no blur filter', (tester) async {
    await seed();
    await open(
      tester,
      overrides: [
        reduceTransparencyProvider.overrideWith((ref) => Stream.value(true)),
      ],
    );

    final locked = find.byKey(LockedPage.pageKey);
    expect(
      find.descendant(of: locked, matching: find.byType(ImageFiltered)),
      findsNothing,
    );
    expect(
      find.descendant(of: locked, matching: find.byType(BackdropFilter)),
      findsNothing,
    );

    await tester.disposeApp();
  });
}

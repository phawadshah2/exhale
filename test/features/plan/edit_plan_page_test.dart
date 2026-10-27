import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:exhale/features/habit/domain/repositories/habit_repository.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/domain/repositories/plan_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/pump_app.dart';

void main() {
  // Friday 16 Oct 2026, 15:42.
  final now = DateTime(2026, 10, 16, 15, 42);
  final today = LogicalDay(2026, 10, 16);
  final yesterday = today.addDays(-1);

  setUp(() async {
    await setUpTestDependencies(FixedClock(now));
    await seedHabit(
      PlanDraft(
        startDay: LogicalDay(2026, 10, 14),
        startLimit: 9,
        quitDay: LogicalDay(2026, 10, 14).addDays(63),
      ),
    );
  });

  tearDown(InjectionContainer.reset);

  // The save reads and writes drift, so real time has to pass between
  // fake-clock pumps.
  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text('Save changes'));
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
  }

  Future<PlanHistory> history(WidgetTester tester) async {
    final result = await tester.runAsync(
      () => sl<PlanRepository>().getHistory(1),
    );
    return (result! as Success<PlanHistory?>).value!;
  }

  Future<void> openEditPlan(WidgetTester tester) async {
    await tester.pumpAppPastSplash(height: 2400);
    await tester.tap(find.byTooltip('Edit plan'));
    await tester.pumpAndSettle();
  }

  testWidgets("saving starts a new plan today and keeps yesterday's limit", (
    tester,
  ) async {
    await openEditPlan(tester);
    expect(
      find.text('Changes start today. Past days keep the limits they had.'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Decrease daily limit'));
    await tester.pump();
    await save(tester);

    final saved = await history(tester);
    expect(saved.plans, hasLength(2));
    expect(saved.limitOn(yesterday), 9);
    expect(saved.limitOn(today), 8);
    expect(saved.current.startDay, today);
    expect(find.byTooltip('Edit plan'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('price is saved with the plan', (tester) async {
    await openEditPlan(tester);

    await tester.enterText(find.byType(TextField).first, '14.50');
    await save(tester);

    final habits = await tester.runAsync(
      () => sl<HabitRepository>().getActive(),
    );
    final habit = (habits! as Success<List<TrackedHabit>>).value.single;
    expect(habit.priceCents, 1450);

    await tester.disposeApp();
  });

  testWidgets('Add a price link opens Edit plan', (tester) async {
    await tester.pumpAppPastSplash(height: 2400);

    await tester.scrollAndTap(find.text('Add a price ›'));
    await tester.pumpAndSettle();

    expect(find.text('Daily limit from today'), findsOneWidget);
    expect(find.text('What it costs'), findsOneWidget);

    await tester.disposeApp();
  });
}

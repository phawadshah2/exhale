import 'dart:async';

import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:exhale/features/habit/domain/repositories/habit_repository.dart';
import 'package:exhale/features/home/presentation/widgets/habit_dashboard.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/providers/onboarding_form_provider.dart';
import 'package:exhale/features/onboarding/presentation/steps/cost_step.dart';
import 'package:exhale/features/onboarding/presentation/steps/habit_step.dart';
import 'package:exhale/features/onboarding/presentation/widgets/currency_chip.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/plan/domain/repositories/plan_repository.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/pump_app.dart';

void main() {
  final today = LogicalDay(2026, 10, 16);
  final plan = PlanDraft(
    startDay: today,
    startLimit: 10,
    quitDay: today.addDays(70),
  );

  setUp(
    () => setUpTestDependencies(FixedClock(DateTime(2026, 10, 16, 15, 42))),
  );
  tearDown(InjectionContainer.reset);

  Future<void> openAddHabit(WidgetTester tester) async {
    await tester.pumpAppPastSplash(height: 2400);
    await tester.longPress(find.byTooltip('Log'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(OnboardingCopy.addHabitTitle));
    await tester.pumpAndSettle();
  }

  Future<void> tapContinue(WidgetTester tester) async {
    await tester.tap(find.text(OnboardingCopy.continueButton).hitTestable());
    await tester.pumpAndSettle();
  }

  OnboardingFormState form(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(HabitStep)))
          .read(onboardingFormProvider);

  Future<List<TrackedHabit>> active(WidgetTester tester) async {
    final result = await tester.runAsync(sl<HabitRepository>().getActive);
    return (result! as Success<List<TrackedHabit>>).value;
  }

  Future<AppSettings> settings(WidgetTester tester) async {
    final result = await tester.runAsync(sl<SettingsRepository>().get);
    return (result! as Success<AppSettings>).value;
  }

  Future<void> seedSettings(AppSettings Function(AppSettings) change) async {
    final repository = sl<SettingsRepository>();
    final current = await repository.get() as Success<AppSettings>;
    await repository.save(change(current.value));
  }

  testWidgets('opens on Habit with its own title, skipping Welcome', (
    tester,
  ) async {
    await seedHabit(plan, habit: Habit.vaping);
    await openAddHabit(tester);

    expect(find.byType(HabitStep), findsOneWidget);
    expect(find.text('1/4'), findsOneWidget);
    expect(find.text(OnboardingCopy.addHabitPrompt), findsOneWidget);
    expect(find.text(OnboardingCopy.addHabitTitle), findsOneWidget);
    expect(find.text(OnboardingCopy.addHabitLead), findsOneWidget);
    expect(find.text(OnboardingCopy.habitTitle), findsNothing);

    await tester.disposeApp();
  });

  testWidgets('tracked habit is disabled', (tester) async {
    await seedHabit(plan, habit: Habit.vaping);
    await openAddHabit(tester);

    expect(find.text(OnboardingCopy.tracking), findsOneWidget);
    expect(form(tester).habitKind, HabitKind.smoking);

    await tester.tap(find.text(Habit.vaping.name));
    await tester.pumpAndSettle();
    expect(form(tester).habitKind, HabitKind.smoking);

    await tester.tap(find.text(Habit.alcohol.name));
    await tester.pumpAndSettle();
    expect(form(tester).habitKind, HabitKind.alcohol);

    await tester.disposeApp();
  });

  testWidgets('with every preset tracked it opens on Something else', (
    tester,
  ) async {
    for (final habit in Habit.presets) {
      await seedHabit(plan, habit: habit);
    }
    await tester.pumpAppPastSplash(height: 2400);
    unawaited(
      GoRouter.of(tester.element(find.byType(HabitDashboard)))
          .push<void>(AppRoutes.addHabit),
    );
    await tester.pumpAndSettle();

    expect(find.text(OnboardingCopy.tracking), findsNWidgets(8));
    expect(form(tester).habitKind, HabitKind.custom);
    expect(form(tester).canContinue, isFalse);

    await tester.disposeApp();
  });

  testWidgets('adding a second habit saves it with a plan and returns Home', (
    tester,
  ) async {
    final vaping = await seedHabit(plan, habit: Habit.vaping);
    await openAddHabit(tester);

    await tapContinue(tester);
    await tapContinue(tester);
    await tapContinue(tester);
    await tester.tap(find.text(OnboardingCopy.dealButton).hitTestable());
    await tester.pumpAndSettle();

    expect(find.byType(HabitDashboard), findsOneWidget);
    final habits = await active(tester);
    expect(habits.map((h) => h.id).first, vaping);
    expect(habits.map((h) => h.habit.kind), [
      HabitKind.vaping,
      HabitKind.smoking,
    ]);
    final added = await tester.runAsync(
      () => sl<PlanRepository>().watchHistory(habits.last.id).first,
    );
    expect(added, isNotNull);

    await tester.disposeApp();
  });

  testWidgets('keeps the saved day and currency', (tester) async {
    await seedHabit(plan, habit: Habit.vaping);
    await seedSettings(
      (s) => s.copyWith(
        currencySymbol: 'CHF',
        wakeMinute: () => 480,
        bedMinute: () => 1320,
      ),
    );
    final before = await settings(tester);
    await openAddHabit(tester);

    expect(form(tester).currency, 'CHF');
    expect(form(tester).wakeMinute, 480);
    expect(form(tester).bedMinute, 1320);

    await tapContinue(tester);
    await tapContinue(tester);
    await tapContinue(tester);
    await tester.tap(find.text(OnboardingCopy.dealButton).hitTestable());
    await tester.pumpAndSettle();

    expect(await settings(tester), before);

    await tester.disposeApp();
  });

  testWidgets('the currency cannot be changed while adding', (tester) async {
    await seedHabit(plan, habit: Habit.vaping);
    await seedSettings((s) => s.copyWith(currencySymbol: 'CHF'));
    await openAddHabit(tester);
    await tapContinue(tester);
    await tapContinue(tester);

    expect(find.byType(CostStep), findsOneWidget);
    await tester.tap(find.byType(CurrencyChip));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoPicker), findsNothing);

    await tester.disposeApp();
  });

  testWidgets('back on the first step returns Home without saving', (
    tester,
  ) async {
    await seedHabit(plan, habit: Habit.vaping);
    await openAddHabit(tester);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(HabitStep), findsNothing);
    expect(find.byType(HabitDashboard), findsOneWidget);
    expect(await active(tester), hasLength(1));

    await tester.disposeApp();
  });
}

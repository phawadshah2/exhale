import 'dart:async';

import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:exhale/features/habit/domain/repositories/habit_repository.dart';
import 'package:exhale/features/habit/domain/usecases/change_habit.dart';
import 'package:exhale/features/home/presentation/widgets/habit_dashboard.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/providers/onboarding_form_provider.dart';
import 'package:exhale/features/onboarding/presentation/steps/amount_step.dart';
import 'package:exhale/features/onboarding/presentation/steps/cost_step.dart';
import 'package:exhale/features/onboarding/presentation/steps/deal_step.dart';
import 'package:exhale/features/onboarding/presentation/steps/habit_step.dart';
import 'package:exhale/features/onboarding/presentation/widgets/currency_chip.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/domain/repositories/plan_repository.dart';
import 'package:exhale/features/plan/presentation/pages/edit_plan_page.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/repositories/settings_repository.dart';
import 'package:exhale/features/tracking/domain/usecases/add_habit_log.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  Future<void> openEditPlan(WidgetTester tester) async {
    await tester.pumpAppPastSplash(height: 2400);
    await tester.tap(find.byTooltip('Edit plan'));
    await tester.pumpAndSettle();
  }

  Future<void> openChangeHabit(WidgetTester tester) async {
    await openEditPlan(tester);
    await tester.tap(find.text('Change habit'));
    await tester.pumpAndSettle();
  }

  Future<void> tapContinue(WidgetTester tester) async {
    await tester.tap(find.text(OnboardingCopy.continueButton).hitTestable());
    await tester.pumpAndSettle();
  }

  /// Vaping is tracked, so the form opens on Smoking: Habit, Amount, Cost.
  Future<void> walkToDeal(WidgetTester tester) async {
    await tapContinue(tester);
    await tapContinue(tester);
    await tapContinue(tester);
    expect(find.byType(DealStep), findsOneWidget);
  }

  Future<void> shake(WidgetTester tester) async {
    await tester.tap(find.text(OnboardingCopy.dealButton).hitTestable());
    await tester.pumpAndSettle();
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.text(OnboardingCopy.replaceConfirm));
    await tester.pumpAndSettle();
  }

  OnboardingFormState form(WidgetTester tester, Type step) =>
      ProviderScope.containerOf(tester.element(find.byType(step)))
          .read(onboardingFormProvider);

  Future<List<TrackedHabit>> active(WidgetTester tester) async {
    final result = await tester.runAsync(sl<HabitRepository>().getActive);
    return (result! as Success<List<TrackedHabit>>).value;
  }

  Future<PlanHistory?> history(WidgetTester tester, int habitId) async {
    final result = await tester.runAsync(
      () => sl<PlanRepository>().getHistory(habitId),
    );
    return (result! as Success<PlanHistory?>).value;
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

  testWidgets('Edit plan offers Change habit with a 44 pt target', (
    tester,
  ) async {
    await seedHabit(plan, habit: Habit.vaping);
    await openEditPlan(tester);

    final button = find.widgetWithText(OutlinedButton, 'Change habit');
    expect(button, findsOneWidget);
    expect(tester.getSize(button).height, greaterThanOrEqualTo(44));

    await tester.disposeApp();
  });

  testWidgets('opens on Habit and skips Welcome and Your day', (tester) async {
    await seedHabit(plan, habit: Habit.vaping);
    await openChangeHabit(tester);

    expect(find.byType(HabitStep), findsOneWidget);
    expect(find.text('1/4'), findsOneWidget);
    expect(find.text(OnboardingCopy.changeHabitPrompt), findsOneWidget);
    expect(find.text(OnboardingCopy.changeHabitTitle), findsOneWidget);
    expect(find.text(OnboardingCopy.changeHabitLead('Vaping')), findsOneWidget);
    expect(find.text(OnboardingCopy.habitTitle), findsNothing);

    await tester.disposeApp();
  });

  testWidgets('the tracked preset is disabled', (tester) async {
    await seedHabit(plan, habit: Habit.vaping);
    await openChangeHabit(tester);

    expect(find.text(OnboardingCopy.tracking), findsOneWidget);
    expect(form(tester, HabitStep).habitKind, HabitKind.smoking);

    await tester.tap(find.text(Habit.vaping.name));
    await tester.pumpAndSettle();
    expect(form(tester, HabitStep).habitKind, HabitKind.smoking);

    await tester.tap(find.text(Habit.alcohol.name));
    await tester.pumpAndSettle();
    expect(form(tester, HabitStep).habitKind, HabitKind.alcohol);

    await tester.disposeApp();
  });

  testWidgets('a custom habit leaves every preset open', (tester) async {
    await seedHabit(
      plan,
      habit: Habit.custom(name: 'Gaming', unit: 'game'),
    );
    await openChangeHabit(tester);

    expect(find.text(OnboardingCopy.tracking), findsNothing);
    expect(form(tester, HabitStep).habitKind, HabitKind.vaping);

    await tester.disposeApp();
  });

  testWidgets('backing out keeps the habit and plan', (tester) async {
    final vaping = await seedHabit(plan, habit: Habit.vaping);
    final before = await history(tester, vaping);
    await openChangeHabit(tester);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(HabitStep), findsNothing);
    expect(find.byType(EditPlanPage), findsOneWidget);
    expect((await active(tester)).map((h) => h.id), [vaping]);
    expect((await history(tester, vaping))!.current, before!.current);

    await tester.disposeApp();
  });

  testWidgets('declining the confirm keeps the habit and the answers', (
    tester,
  ) async {
    final vaping = await seedHabit(plan, habit: Habit.vaping);
    await openChangeHabit(tester);
    await tapContinue(tester);

    ProviderScope.containerOf(tester.element(find.byType(AmountStep)))
        .read(onboardingFormProvider.notifier)
        .setStartLimit(14);
    await tester.pumpAndSettle();
    await tapContinue(tester);
    await tapContinue(tester);

    await shake(tester);
    expect(
      find.text(OnboardingCopy.replaceTitle('Vaping', 'Smoking')),
      findsOneWidget,
    );
    expect(
      find.text(OnboardingCopy.replaceMessage('Vaping', 'Smoking')),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(DealStep), findsOneWidget);
    expect(form(tester, DealStep).startLimit, 14);
    expect(form(tester, DealStep).habitKind, HabitKind.smoking);
    expect((await active(tester)).map((h) => h.id), [vaping]);

    await tester.disposeApp();
  });

  testWidgets('replacing shows the new habit on Home with no logs', (
    tester,
  ) async {
    final vaping = await seedHabit(plan, habit: Habit.vaping);
    await sl<AddHabitLog>()(
      AddHabitLogInput(habitId: vaping, loggedAt: DateTime(2026, 10, 16, 9)),
    );
    await openChangeHabit(tester);
    await walkToDeal(tester);

    await shake(tester);
    await confirm(tester);

    expect(find.byType(DealStep), findsNothing);
    final dashboard = tester.widget<HabitDashboard>(
      find.byType(HabitDashboard),
    );
    final habits = await active(tester);
    expect(habits.map((h) => h.habit), [Habit.smoking]);
    expect(dashboard.habitId, habits.single.id);
    expect(find.textContaining('Smoking'), findsWidgets);
    expect(find.textContaining('Vaping'), findsNothing);
    expect(
      find.text('No ${Habit.smoking.units} logged today. Nice start.'),
      findsOneWidget,
    );
    final started = await history(tester, habits.single.id);
    expect(started!.current.startDay, today);

    await tester.disposeApp();
  });

  testWidgets('old logs stay stored', (tester) async {
    final vaping = await seedHabit(plan, habit: Habit.vaping);
    await sl<AddHabitLog>()(
      AddHabitLogInput(habitId: vaping, loggedAt: DateTime(2026, 10, 16, 9)),
    );
    await openChangeHabit(tester);
    await walkToDeal(tester);

    await shake(tester);
    await confirm(tester);

    final database = sl<AppDatabase>();
    final logs = await tester.runAsync(
      () => database.select(database.habitLogs).get(),
    );
    expect(logs!.map((log) => log.habitId), [vaping]);

    await tester.disposeApp();
  });

  testWidgets('wake, bed and currency are unchanged', (tester) async {
    await seedHabit(plan, habit: Habit.vaping);
    await seedSettings(
      (s) => s.copyWith(
        currencySymbol: 'CHF',
        wakeMinute: () => 480,
        bedMinute: () => 1320,
      ),
    );
    final before = await settings(tester);
    await openChangeHabit(tester);
    expect(form(tester, HabitStep).currency, 'CHF');
    expect(form(tester, HabitStep).wakeMinute, 480);
    expect(form(tester, HabitStep).bedMinute, 1320);
    await walkToDeal(tester);

    await shake(tester);
    await confirm(tester);

    expect(await settings(tester), before);
    expect((await active(tester)).single.habit, Habit.smoking);

    await tester.disposeApp();
  });

  testWidgets('the currency cannot be changed', (tester) async {
    await seedHabit(plan, habit: Habit.vaping);
    await openChangeHabit(tester);
    await tapContinue(tester);
    await tapContinue(tester);

    expect(find.byType(CostStep), findsOneWidget);
    await tester.tap(find.byType(CurrencyChip));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoPicker), findsNothing);

    await tester.disposeApp();
  });

  testWidgets('two presses replace once', (tester) async {
    await seedHabit(plan, habit: Habit.vaping);
    await openChangeHabit(tester);
    await walkToDeal(tester);

    final press = tester
        .widget<FilledButton>(
          find.widgetWithText(FilledButton, OnboardingCopy.dealButton),
        )
        .onPressed!;
    press();
    press();
    await tester.pumpAndSettle();

    expect(find.text(OnboardingCopy.replaceConfirm), findsOneWidget);
    await confirm(tester);

    expect(find.text(OnboardingCopy.replaceConfirm), findsNothing);
    final database = sl<AppDatabase>();
    final rows = await tester.runAsync(
      () => database.select(database.habits).get(),
    );
    expect(rows, hasLength(2));
    expect((await active(tester)).single.habit, Habit.smoking);

    await tester.disposeApp();
  });

  testWidgets('a press during the save asks nothing more', (tester) async {
    await seedHabit(plan, habit: Habit.vaping);
    sl
      ..unregister<ChangeHabit>()
      ..registerFactory<ChangeHabit>(_HangingChange.new);
    await openChangeHabit(tester);
    await walkToDeal(tester);

    // The busy button drops its handler, so a press from the same frame as
    // the save starting has to use the one from before.
    final press = tester
        .widget<FilledButton>(
          find.widgetWithText(FilledButton, OnboardingCopy.dealButton),
        )
        .onPressed!;
    await shake(tester);
    await tester.tap(find.text(OnboardingCopy.replaceConfirm));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(form(tester, DealStep).isSubmitting, isTrue);

    press();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(OnboardingCopy.replaceConfirm), findsNothing);

    await tester.disposeApp();
  });

  testWidgets('a failed save stays on The deal with the error', (tester) async {
    final vaping = await seedHabit(plan, habit: Habit.vaping);
    sl
      ..unregister<ChangeHabit>()
      ..registerFactory<ChangeHabit>(_FailingChange.new);
    await openChangeHabit(tester);
    await walkToDeal(tester);

    await shake(tester);
    await confirm(tester);

    expect(find.byType(DealStep), findsOneWidget);
    expect(form(tester, DealStep).errorMessage, isNotNull);
    expect(find.text(form(tester, DealStep).errorMessage!), findsOneWidget);
    expect((await active(tester)).map((h) => h.id), [vaping]);

    await tester.disposeApp();
  });

  testWidgets('replacing with Edit plan underneath does not throw', (
    tester,
  ) async {
    await seedHabit(plan, habit: Habit.vaping);
    await openChangeHabit(tester);
    await walkToDeal(tester);
    expect(find.byType(EditPlanPage, skipOffstage: false), findsOneWidget);

    await shake(tester);
    await confirm(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(EditPlanPage, skipOffstage: false), findsNothing);
    expect(find.byType(HabitDashboard), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('on iOS, replacing with Edit plan underneath does not throw', (
    tester,
  ) async {
    // The native alert answers Replace, its second action.
    const channel = MethodChannel('exhale/native_ui');
    final messenger = tester.binding.defaultBinaryMessenger
      ..setMockMethodCallHandler(
        channel,
        (call) async => call.method == 'showAlert' ? 1 : false,
      );
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    await seedHabit(plan, habit: Habit.vaping);
    await openChangeHabit(tester);
    await walkToDeal(tester);

    await shake(tester);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(HabitDashboard), findsOneWidget);

    await tester.disposeApp();
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('a link to a habit no longer tracked returns Home', (
    tester,
  ) async {
    final vaping = await seedHabit(plan, habit: Habit.vaping);
    await tester.pumpAppPastSplash(height: 2400);

    unawaited(
      GoRouter.of(tester.element(find.byType(HabitDashboard)))
          .push<void>(AppRoutes.changeHabitFor(vaping + 1)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(HabitStep), findsNothing);
    expect(find.byType(HabitDashboard), findsOneWidget);

    await tester.disposeApp();
  });
}

class _FailingChange implements ChangeHabit {
  @override
  Future<Result<TrackedHabit>> call(ChangeHabitInput input) async =>
      const FailureResult<TrackedHabit>(StorageFailure());
}

/// Never finishes, to hold the form in its saving state.
class _HangingChange implements ChangeHabit {
  @override
  Future<Result<TrackedHabit>> call(ChangeHabitInput input) =>
      Completer<Result<TrackedHabit>>().future;
}

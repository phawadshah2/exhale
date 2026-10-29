import 'package:exhale/app/router/app_routes.dart';
import 'package:exhale/core/data/storage_guard.dart';
import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/domain/entities/habit_draft.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:exhale/features/habit/domain/repositories/habit_repository.dart';
import 'package:exhale/features/home/presentation/pages/home_page.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/pages/habit_picker_page.dart';
import 'package:exhale/features/onboarding/presentation/providers/onboarding_form_provider.dart';
import 'package:exhale/features/onboarding/presentation/steps/cost_step.dart';
import 'package:exhale/features/onboarding/presentation/steps/deal_step.dart';
import 'package:exhale/features/onboarding/presentation/steps/welcome_step.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/domain/repositories/plan_repository.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/pump_app.dart';

void main() {
  final today = LogicalDay.fromDate(DateTime(2026, 10, 20));

  setUp(() => setUpTestDependencies(FixedClock(DateTime(2026, 10, 20, 9))));
  tearDown(InjectionContainer.reset);

  Future<void> tapContinue(WidgetTester tester) async {
    await tester.tap(find.text(OnboardingCopy.continueButton).hitTestable());
    await tester.pumpAndSettle();
  }

  OnboardingFormController controller(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(DealStep)))
          .read(onboardingFormProvider.notifier);

  OnboardingFormState form(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(DealStep)))
          .read(onboardingFormProvider);

  /// The full app on first run, walked to The deal with smoking and the
  /// defaults; [price] is typed on the Cost step when given.
  Future<void> toDeal(WidgetTester tester, {String? price}) async {
    await tester.pumpAppPastSplash(height: 2400);
    GoRouter.of(tester.element(find.byType(HabitPickerPage)))
        .go(AppRoutes.onboarding);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(WelcomeStep));
    await tester.pump();
    await tester.tap(find.text(OnboardingCopy.welcomeButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Habit.smoking.name));
    await tester.pumpAndSettle();
    await tapContinue(tester);
    await tapContinue(tester);
    if (price != null) {
      await tester.enterText(
        find.descendant(
          of: find.byType(CostStep),
          matching: find.byType(TextField),
        ),
        price,
      );
      await tester.pump();
    }
    await tapContinue(tester);
    await tapContinue(tester);
  }

  Finder shakeOnIt() => find.text(OnboardingCopy.dealButton).hitTestable();

  String title(int amount, LogicalDay quitDay) =>
      OnboardingCopy.dealTitle(amount, AppFormat.monthDay(quitDay));

  testWidgets('Suggested is preselected and the presets move the date', (
    tester,
  ) async {
    await toDeal(tester);

    expect(find.text('6/6'), findsOneWidget);
    expect(find.text(OnboardingCopy.dealPrompt), findsOneWidget);
    expect(find.text(title(9, today.addDays(63))), findsOneWidget);
    expect(form(tester).quitPreset, QuitPreset.suggested);
    expect(find.text('63 days'), findsOneWidget);
    expect(find.text(OnboardingCopy.tomorrow), findsOneWidget);
    expect(find.text(OnboardingCopy.paceLine(107)), findsOneWidget);

    await tester.tap(find.text(QuitPreset.weeks4.label));
    await tester.pumpAndSettle();
    expect(find.text(title(9, today.addDays(28))), findsOneWidget);
    expect(find.text('28 days'), findsOneWidget);
    expect(form(tester).quitPreset, QuitPreset.weeks4);

    await tester.tap(find.text(OnboardingCopy.pick));
    await tester.pumpAndSettle();
    tester
        .widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker))
        .onDateTimeChanged(today.addDays(40).toLocalDate());
    await tester.tap(find.byTooltip('Done'));
    await tester.pumpAndSettle();

    expect(find.text(title(9, today.addDays(40))), findsOneWidget);
    expect(form(tester).quitPreset, isNull);

    await tester.disposeApp();
  });

  testWidgets('a steep plan shows the warning', (tester) async {
    await toDeal(tester);
    controller(tester).setQuitDay(today.addDays(5));
    await tester.pumpAndSettle();

    expect(
      find.text(
        "That's more than one fewer a day. A later date may feel easier.",
      ),
      findsOneWidget,
    );

    await tester.disposeApp();
  });

  testWidgets('Back a year shows only with a price', (tester) async {
    await toDeal(tester);
    expect(find.text(OnboardingCopy.backAYear), findsNothing);
    await tester.disposeApp();

    await InjectionContainer.reset();
    await setUpTestDependencies(FixedClock(DateTime(2026, 10, 20, 9)));
    await toDeal(tester, price: '14.50');
    expect(find.text(OnboardingCopy.backAYear), findsOneWidget);
    final state = form(tester);
    expect(
      find.text(
        AppFormat.money(
          state.yearlyCostCents!,
          symbol: state.currency,
          wholeUnits: true,
        ),
      ),
      findsOneWidget,
    );

    await tester.disposeApp();
  });

  testWidgets('the biggest daily amount suggests 90 days', (tester) async {
    await toDeal(tester);
    controller(tester).setStartLimit(80);
    await tester.pumpAndSettle();

    expect(find.text(title(80, today.addDays(90))), findsOneWidget);
    expect(find.text('90 days'), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('Shake on it saves the habit, plan and settings', (tester) async {
    await toDeal(tester);
    controller(tester).setCurrency('£');
    await tester.pump();

    await tester.tap(shakeOnIt());
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    await tester.runAsync(() async {
      final habits =
          await sl<HabitRepository>().getActive()
              as Success<List<TrackedHabit>>;
      expect(habits.value, hasLength(1));
      expect(habits.value.single.habit.kind, HabitKind.smoking);

      final history = await sl<PlanRepository>().getHistory(
        habits.value.single.id,
      ) as Success<PlanHistory?>;
      final plan = history.value!.plans.single;
      expect(plan.startDay, today);
      expect(plan.startLimit, 9);
      expect(plan.quitDay, today.addDays(63));

      final settings =
          await sl<SettingsRepository>().get() as Success<AppSettings>;
      expect(settings.value.wakeMinute, 450);
      expect(settings.value.bedMinute, 1410);
      expect(settings.value.currencySymbol, '£');
    });

    await tester.disposeApp();
  });

  testWidgets('a failed save keeps the answers and the retry saves one', (
    tester,
  ) async {
    final real = sl<HabitRepository>();
    sl
      ..unregister<HabitRepository>()
      ..registerSingleton<HabitRepository>(_FailOnceHabitRepository(real));
    await toDeal(tester, price: '14.50');
    await tester.tap(find.text(QuitPreset.weeks8.label));
    await tester.pumpAndSettle();

    await tester.tap(shakeOnIt());
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsNothing);
    final failed = form(tester);
    expect(failed.errorMessage, isNotNull);
    expect(find.text(failed.errorMessage!), findsOneWidget);
    expect(failed.isSubmitting, isFalse);
    expect(failed.habitKind, HabitKind.smoking);
    expect(failed.priceText, '14.50');
    expect(failed.quitPreset, QuitPreset.weeks8);
    expect(find.text(title(9, today.addDays(56))), findsOneWidget);

    await tester.tap(shakeOnIt());
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    await tester.runAsync(() async {
      final habits =
          await sl<HabitRepository>().getActive()
              as Success<List<TrackedHabit>>;
      expect(habits.value, hasLength(1));
      expect(habits.value.single.priceCents, 1450);
    });

    await tester.disposeApp();
  });

  testWidgets('a fast double tap saves one habit', (tester) async {
    await toDeal(tester);

    // Both presses land before the first save gets past its first await.
    tester
          .widget<FilledButton>(
            find.descendant(
              of: find.byType(DealStep),
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed!
      ..call()
      ..call();
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    await tester.runAsync(() async {
      final habits =
          await sl<HabitRepository>().getActive()
              as Success<List<TrackedHabit>>;
      expect(habits.value, hasLength(1));
    });

    await tester.disposeApp();
  });
}

/// The real repository, except the first [add] fails as storage would.
class _FailOnceHabitRepository implements HabitRepository {
  _FailOnceHabitRepository(this._real);

  final HabitRepository _real;
  bool _failed = false;

  @override
  Future<Result<TrackedHabit>> add(
    HabitDraft draft, {
    required DateTime createdAt,
  }) {
    if (_failed) return _real.add(draft, createdAt: createdAt);
    _failed = true;
    return guardStorage<TrackedHabit>(
      'FailOnceHabitRepository',
      () async => throw const FormatException('disk full'),
    );
  }

  @override
  Stream<List<TrackedHabit>> watchActive() => _real.watchActive();

  @override
  Future<Result<List<TrackedHabit>>> getActive() => _real.getActive();

  @override
  Future<Result<void>> update(TrackedHabit habit) => _real.update(habit);

  @override
  Future<Result<void>> archive(int id, {required DateTime at}) =>
      _real.archive(id, at: at);
}

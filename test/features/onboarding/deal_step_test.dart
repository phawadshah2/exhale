import 'package:exhale/core/data/storage_guard.dart';
import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/domain/entities/habit_draft.dart';
import 'package:exhale/features/habit/domain/entities/price_history.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:exhale/features/habit/domain/repositories/habit_repository.dart';
import 'package:exhale/features/home/presentation/pages/home_page.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/providers/onboarding_form_provider.dart';
import 'package:exhale/features/onboarding/presentation/steps/deal_step.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/domain/repositories/plan_repository.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/onboarding.dart';
import '../../helpers/pump_app.dart';

void main() {
  final today = LogicalDay.fromDate(DateTime(2026, 10, 20));

  setUp(() => setUpTestDependencies(FixedClock(DateTime(2026, 10, 20, 9))));
  tearDown(InjectionContainer.reset);

  OnboardingFormController controller(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(DealStep)))
          .read(onboardingFormProvider.notifier);

  OnboardingFormState form(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(DealStep)))
          .read(onboardingFormProvider);

  Finder go(String? pace, LogicalDay quitDay) => find.descendant(
    of: planButton(),
    matching: find.text(
      OnboardingCopy.dealGo(pace, AppFormat.monthDay(quitDay)),
    ),
  );

  Future<void> save(WidgetTester tester) async {
    await tester.tap(planButton().hitTestable());
    await tester.pumpAndSettle();
  }

  testWidgets('the suggested pace is open and the others move the date', (
    tester,
  ) async {
    await pumpAppToPlan(tester);

    // Smoking at 10 a day suggests 70 days; Gentle (84) wins the tie.
    expect(find.text(OnboardingCopy.dealEyebrow(10)), findsOneWidget);
    expect(find.text(OnboardingCopy.dealHeadline), findsOneWidget);
    expect(find.text(OnboardingCopy.suggested), findsOneWidget);
    expect(form(tester).quitDay, today.addDays(84));
    expect(go('Gentle', today.addDays(84)), findsOneWidget);

    await tester.tap(find.text('Brisk'));
    await tester.pumpAndSettle();
    expect(form(tester).quitDay, today.addDays(28));
    expect(go('Brisk', today.addDays(28)), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('Pick my own date opens the wheel and closes the paces', (
    tester,
  ) async {
    await pumpAppToPlan(tester);

    await tester.tap(find.text(OnboardingCopy.pickOwnDate));
    await tester.pumpAndSettle();
    tester
        .widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker))
        .onDateTimeChanged(today.addDays(40).toLocalDate());
    await tester.tap(find.byTooltip('Done'));
    await tester.pumpAndSettle();

    expect(form(tester).quitDay, today.addDays(40));
    expect(go(null, today.addDays(40)), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('a steep plan shows the warning', (tester) async {
    await pumpAppToPlan(tester);
    controller(tester).setQuitDay(today.addDays(5));
    await tester.pumpAndSettle();

    expect(find.text(OnboardingCopy.steepWarning), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('the dots and the button loop, but not under Reduce Motion', (
    tester,
  ) async {
    await pumpAppToPlan(tester);

    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(SchedulerBinding.instance.transientCallbackCount, greaterThan(0));

    reduceMotion(tester);
    await tester.pumpAndSettle();
    expect(SchedulerBinding.instance.transientCallbackCount, 0);

    await tester.disposeApp();
  });

  testWidgets('the button saves the habit, plan, name and settings', (
    tester,
  ) async {
    await pumpAppToPlan(tester);
    await tester.tap(find.text('Steady'));
    await tester.pumpAndSettle();

    await save(tester);

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
      expect(plan.startLimit, 10);
      expect(plan.quitDay, today.addDays(56));

      final settings =
          await sl<SettingsRepository>().get() as Success<AppSettings>;
      expect(settings.value.wakeMinute, 450);
      expect(settings.value.bedMinute, 1410);
      expect(settings.value.userName, 'Alex');
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
    await pumpAppToPlan(tester, price: '14.50');
    await tester.tap(find.text('Steady'));
    await tester.pumpAndSettle();

    await save(tester);

    expect(find.byType(HomePage), findsNothing);
    final failed = form(tester);
    expect(failed.errorMessage, isNotNull);
    expect(find.text(failed.errorMessage!), findsOneWidget);
    expect(failed.isSubmitting, isFalse);
    expect(failed.habitKind, HabitKind.smoking);
    expect(failed.priceText, '14.50');
    expect(failed.quitDay, today.addDays(56));

    await save(tester);

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

  testWidgets('a failed check for an existing habit saves nothing', (
    tester,
  ) async {
    final real = sl<HabitRepository>();
    final repository = _FailReadsRepository(real);
    sl
      ..unregister<HabitRepository>()
      ..registerSingleton<HabitRepository>(repository);
    await pumpAppToPlan(tester);
    final before = await tester.runAsync(
      () async => await sl<SettingsRepository>().get() as Success<AppSettings>,
    );

    repository.failing = true;
    await save(tester);
    repository.failing = false;

    expect(find.byType(HomePage), findsNothing);
    final failed = form(tester);
    expect(failed.errorMessage, isNotNull);
    expect(failed.isSubmitting, isFalse);
    await tester.runAsync(() async {
      final habits = await real.getActive() as Success<List<TrackedHabit>>;
      expect(habits.value, isEmpty);
      final after =
          await sl<SettingsRepository>().get() as Success<AppSettings>;
      expect(after.value.wakeMinute, before!.value.wakeMinute);
      expect(after.value.currencySymbol, before.value.currencySymbol);
    });

    await tester.disposeApp();
  });

  testWidgets('a fast double tap saves one habit', (tester) async {
    await pumpAppToPlan(tester);

    // Both presses land before the first save gets past its first await.
    tester.widget<FilledButton>(planButton()).onPressed!
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

/// The real repository, except [getActive] fails while [failing].
class _FailReadsRepository implements HabitRepository {
  _FailReadsRepository(this._real);

  final HabitRepository _real;
  bool failing = false;

  @override
  Future<Result<List<TrackedHabit>>> getActive() => failing
      ? guardStorage<List<TrackedHabit>>(
          'FailReadsRepository',
          () async => throw const FormatException('disk error'),
        )
      : _real.getActive();

  @override
  Future<Result<TrackedHabit>> add(
    HabitDraft draft, {
    required DateTime createdAt,
  }) => _real.add(draft, createdAt: createdAt);

  @override
  Stream<List<TrackedHabit>> watchActive() => _real.watchActive();

  @override
  Future<Result<void>> update(TrackedHabit habit) => _real.update(habit);

  @override
  Future<Result<void>> archive(int id, {required DateTime at}) =>
      _real.archive(id, at: at);

  @override
  Stream<List<PricePoint>> watchPrices(int habitId) =>
      _real.watchPrices(habitId);

  @override
  Future<Result<void>> setPrice(
    int habitId, {
    required LogicalDay day,
    required int? priceCents,
    required int unitsPerContainer,
  }) => _real.setPrice(
    habitId,
    day: day,
    priceCents: priceCents,
    unitsPerContainer: unitsPerContainer,
  );
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

  @override
  Stream<List<PricePoint>> watchPrices(int habitId) =>
      _real.watchPrices(habitId);

  @override
  Future<Result<void>> setPrice(
    int habitId, {
    required LogicalDay day,
    required int? priceCents,
    required int unitsPerContainer,
  }) => _real.setPrice(
    habitId,
    day: day,
    priceCents: priceCents,
    unitsPerContainer: unitsPerContainer,
  );
}

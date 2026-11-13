import 'package:exhale/app/app.dart';
import 'package:exhale/app/router/app_router.dart';
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
import 'package:exhale/features/paywall/data/fake/fake_store_repository.dart';
import 'package:exhale/features/paywall/presentation/pages/paywall_page.dart';
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

  Future<void> pickDate(WidgetTester tester, LogicalDay day) async {
    await tester.tap(find.text(OnboardingCopy.pickOwnDate));
    await tester.pumpAndSettle();
    tester
        .widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker))
        .onDateTimeChanged(day.toLocalDate());
    await tester.tap(find.byTooltip('Done'));
    await tester.pumpAndSettle();
  }

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

  testWidgets("each quit date sits at its card's right edge", (tester) async {
    await pumpAppToPlan(tester);

    final dates = [
      for (final days in const [28, 56, 84])
        find.text(AppFormat.monthDay(today.addDays(days))),
    ];
    // Inside the 24 pt page margin, the 1 pt border and the 16 pt padding;
    // the open card's border is half a point thicker.
    final width = tester.getSize(find.byType(DealStep)).width;
    for (final date in dates) {
      expect(
        tester.getTopRight(date.first).dx,
        closeTo(width - 24 - 1 - 16, 0.6),
      );
    }

    await tester.disposeApp();
  });

  testWidgets('Pick my own date sits above the button', (tester) async {
    await pumpAppToPlan(tester);

    expect(
      tester.getBottomLeft(find.text(OnboardingCopy.pickOwnDate)).dy,
      lessThan(tester.getTopLeft(planButton()).dy),
    );
    expect(
      tester.getTopLeft(find.text(OnboardingCopy.dealFinePrint)).dy,
      greaterThan(tester.getBottomLeft(planButton()).dy),
    );

    await tester.disposeApp();
  });

  testWidgets('Pick my own date adds a card that stays and selects again', (
    tester,
  ) async {
    await pumpAppToPlan(tester);
    expect(find.text(OnboardingCopy.customPace), findsNothing);

    await pickDate(tester, today.addDays(40));
    expect(form(tester).quitDay, today.addDays(40));
    expect(go(null, today.addDays(40)), findsOneWidget);
    expect(find.text(OnboardingCopy.customPace), findsOneWidget);
    expect(find.text(OnboardingCopy.planLength(40)), findsOneWidget);
    expect(OnboardingCopy.planLength(40), '5 wk 5 d');

    await tester.tap(find.text('Gentle'));
    await tester.pumpAndSettle();
    expect(form(tester).quitDay, today.addDays(84));
    expect(find.text(OnboardingCopy.customPace), findsOneWidget);
    // The form keeps it, so leaving the step does not lose the card.
    expect(form(tester).ownQuitDay, today.addDays(40));

    await tester.tap(find.text(OnboardingCopy.customPace));
    await tester.pumpAndSettle();
    expect(form(tester).quitDay, today.addDays(40));

    await tester.disposeApp();
  });

  testWidgets('closed cards ring their stages, the selected one lists them', (
    tester,
  ) async {
    await pumpAppToPlan(tester);

    // 10 a day: Brisk drops every 2 to 3 days, Steady every 5 to 6.
    expect(find.text(OnboardingCopy.stageSpan(2, 3)), findsOneWidget);
    expect(find.text(OnboardingCopy.stageSpan(5, 6)), findsOneWidget);
    expect(find.text(OnboardingCopy.stagesLine(10, 8, 9)), findsOneWidget);
    expect(OnboardingCopy.stagesLine(10, 8, 9), '10 stages, 8–9 days each');
    expect(OnboardingCopy.stagesLine(1, 1, 1), '1 stage, 1 day each');
    expect(
      find.text(
        "Each square is a day; its number is that day's limit. Today is "
        'outlined.',
      ),
      findsOneWidget,
    );

    await tester.disposeApp();
  });

  testWidgets('the grid keeps 7 to 14 columns and up to 7 rows', (
    tester,
  ) async {
    await pumpAppToPlan(tester);

    // Squares carrying a limit, and the rows they and the quit day's check
    // sit on.
    (int, int) grid() {
      final summary = find.byKey(DealStep.gridKey);
      final squares = find.descendant(of: summary, matching: find.byType(Text));
      final check = find.descendant(of: summary, matching: find.byType(Icon));
      // Centres within 4 pt share a row; the check sits a hair off the
      // numbers.
      final ys = [
        for (final element in [...squares.evaluate(), ...check.evaluate()])
          tester.getCenter(find.byWidget(element.widget)).dy,
      ]..sort();
      var rows = ys.isEmpty ? 0 : 1;
      for (var i = 1; i < ys.length; i++) {
        if (ys[i] - ys[i - 1] > 4) rows++;
      }
      return (squares.evaluate().length, rows);
    }

    expect(grid(), (84, 7));

    await tester.tap(find.text('Brisk'));
    await tester.pumpAndSettle();
    expect(grid(), (28, 5));

    await pickDate(tester, today.addDays(180));
    expect(grid(), (26, 4));
    expect(find.text(OnboardingCopy.gridNote(7)), findsOneWidget);

    // Short plans keep 7 columns and take fewer rows, not huge squares.
    await pickDate(tester, today.addDays(20));
    expect(grid(), (20, 3));
    await pickDate(tester, today.addDays(3));
    expect(grid(), (3, 1));
    final card = tester.getSize(find.byKey(DealStep.gridKey)).width;
    expect(
      tester.getSize(find.byKey(DealStep.gridKey)).height,
      lessThan(card / 6),
    );

    await tester.disposeApp();
  });

  testWidgets('a steep plan shows the warning', (tester) async {
    await pumpAppToPlan(tester);
    controller(tester).setQuitDay(today.addDays(5));
    await tester.pumpAndSettle();

    expect(find.text(OnboardingCopy.steepWarning), findsOneWidget);

    await tester.disposeApp();
  });

  testWidgets('the button loops, but not under Reduce Motion', (tester) async {
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

  testWidgets('a double tap on See my plan does not save the plan', (
    tester,
  ) async {
    reduceMotion(tester);
    await tester.pumpAppPastSplash(height: 2400);
    await tester.tap(find.text(OnboardingCopy.welcomeButton));
    await settleChat(tester);
    await chatToPlan(tester, open: false);

    // With motion, so the pages slide. The plan's save sits where See my
    // plan was; the page view ignores the second tap, most of the way
    // through the slide.
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
    await tester.pump();
    final spot = tester.getCenter(find.text(OnboardingCopy.chatSeePlan));
    await tester.tapAt(spot);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tapAt(spot);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(DealStep), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
    await tester.runAsync(() async {
      final habits =
          await sl<HabitRepository>().getActive()
              as Success<List<TrackedHabit>>;
      expect(habits.value, isEmpty);
    });

    // Once the plan has settled, its button saves.
    reduceMotion(tester);
    await tester.pump();
    await tester.tapAt(spot);
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);

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

  group('unpaid', () {
    setUp(() async {
      await InjectionContainer.reset();
      await setUpTestDependencies(
        FixedClock(DateTime(2026, 10, 20, 9)),
        store: FakeStoreRepository(),
      );
    });

    testWidgets('the button saves, then opens the paywall', (tester) async {
      await pumpAppToPlan(tester);

      await save(tester);

      expect(find.byKey(PaywallPage.pageKey), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);

      await tester.disposeApp();
    });

    testWidgets('back from the paywall, another pace saves over the plan', (
      tester,
    ) async {
      await pumpAppToPlan(tester);
      await save(tester);
      ProviderScope.containerOf(tester.element(find.byType(ExhaleApp)))
          .read(routerProvider)
          .pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Brisk'));
      await tester.pumpAndSettle();
      await save(tester);

      expect(find.byKey(PaywallPage.pageKey), findsOneWidget);
      await tester.runAsync(() async {
        final habits =
            await sl<HabitRepository>().getActive()
                as Success<List<TrackedHabit>>;
        expect(habits.value, hasLength(1));
        final history = await sl<PlanRepository>().getHistory(
          habits.value.single.id,
        ) as Success<PlanHistory?>;
        expect(history.value!.plans.single.quitDay, today.addDays(28));
      });

      await tester.disposeApp();
    });
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

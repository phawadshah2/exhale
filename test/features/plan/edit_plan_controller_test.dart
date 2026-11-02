import 'package:exhale/app/bootstrap.dart';
import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/domain/entities/price_history.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:exhale/features/habit/domain/repositories/habit_repository.dart';
import 'package:exhale/features/habit/domain/usecases/set_habit_price.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/plan/domain/repositories/plan_repository.dart';
import 'package:exhale/features/plan/domain/usecases/save_plan.dart';
import 'package:exhale/features/plan/presentation/providers/edit_plan_provider.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/pump_app.dart';

/// Fails the first save, then behaves like the real use case.
class _FailFirstPlan implements SavePlan {
  _FailFirstPlan(this._inner);
  final SavePlan _inner;
  int calls = 0;

  @override
  Future<Result<ReductionPlan>> call(SavePlanInput input) async {
    calls++;
    if (calls == 1) {
      return const FailureResult<ReductionPlan>(StorageFailure());
    }
    return await _inner(input);
  }
}

class _FailingPrice implements SetHabitPrice {
  @override
  Future<Result<void>> call(SetHabitPriceInput input) async =>
      const FailureResult<void>(StorageFailure());
}

void main() {
  // Friday 16 Oct 2026, 15:42.
  final now = DateTime(2026, 10, 16, 15, 42);
  final today = LogicalDay(2026, 10, 16);
  final start = today.addDays(-26);

  // On day 26 of 63 from 9 a day: limit 6, stage 4.
  final running = PlanDraft(
    startDay: start,
    startLimit: 9,
    quitDay: start.addDays(63),
  );

  setUp(() => setUpTestDependencies(FixedClock(now)));

  tearDown(InjectionContainer.reset);

  Future<ProviderContainer> open({List<Override> overrides = const []}) async {
    final container =
        ProviderContainer.test(
            overrides: [...await startupOverrides(), ...overrides],
          )
          ..listen(activeHabitsProvider, (_, _) {})
          ..listen(planHistoryProvider(1), (_, _) {});
    await container.read(activeHabitsProvider.future);
    await container.read(planHistoryProvider(1).future);
    container.listen(editPlanProvider(1), (_, _) {});
    return container;
  }

  Future<PlanHistory> history() async => (await sl<PlanRepository>().getHistory(
    1,
  ) as Success<PlanHistory?>).value!;

  Future<List<PricePoint>> points() =>
      sl<HabitRepository>().watchPrices(1).first;

  Future<TrackedHabit> stored() async =>
      (await sl<HabitRepository>().getActive() as Success<List<TrackedHabit>>)
          .value
          .single;

  group('saving', () {
    test('only the price: the plan and its stage stay, one point', () async {
      await seedHabit(running, priceCents: 1000);
      final container = await open();
      final controller = container.read(editPlanProvider(1).notifier);
      expect((await history()).current.stageOn(today)!.number, 4);

      controller.setPriceText('14.50');
      final form = container.read(editPlanProvider(1));
      expect(form.planChanged, isFalse);
      expect(form.priceChanged, isTrue);
      expect(form.canSave, isTrue);

      expect(await controller.save(), isTrue);

      final saved = await history();
      expect(saved.plans, hasLength(1));
      expect(saved.current.stageOn(today)!.number, 4);
      expect((await stored()).priceCents, 1450);
      expect(await points(), [
        PricePoint(fromDay: start, priceCents: 1000, unitsPerContainer: 20),
        PricePoint(fromDay: today, priceCents: 1450, unitsPerContainer: 20),
      ]);
    });

    test('only the units: one point and no plan', () async {
      await seedHabit(running, priceCents: 1000);
      final container = await open();
      final controller = container.read(editPlanProvider(1).notifier)
        ..setUnitsPerContainer(10);

      expect(container.read(editPlanProvider(1)).priceChanged, isTrue);
      expect(await controller.save(), isTrue);

      expect((await history()).plans, hasLength(1));
      expect((await points()).last.unitsPerContainer, 10);
    });

    test('clearing the price saves no price and no plan', () async {
      await seedHabit(running, priceCents: 1000);
      final container = await open();
      final controller = container.read(editPlanProvider(1).notifier)
        ..setPriceText('');

      expect(await controller.save(), isTrue);

      expect((await history()).plans, hasLength(1));
      expect((await stored()).priceCents, isNull);
    });

    test('a new limit starts one plan and writes no point', () async {
      await seedHabit(running, priceCents: 1000);
      final container = await open();
      final controller = container.read(editPlanProvider(1).notifier)
        ..setDailyLimit(5);

      final form = container.read(editPlanProvider(1));
      expect(form.planChanged, isTrue);
      expect(form.priceChanged, isFalse);
      expect(form.canSave, isTrue);
      expect(await controller.save(), isTrue);

      final saved = await history();
      expect(saved.plans, hasLength(2));
      expect(saved.current.startDay, today);
      expect(saved.current.startLimit, 5);
      expect(await points(), hasLength(1));
    });

    test('a new date starts one plan and writes no point', () async {
      await seedHabit(running, priceCents: 1000);
      final container = await open();
      final controller = container.read(editPlanProvider(1).notifier)
        ..setQuitDay(today.addDays(50));

      expect(container.read(editPlanProvider(1)).planChanged, isTrue);
      expect(await controller.save(), isTrue);

      final saved = await history();
      expect(saved.plans, hasLength(2));
      expect(saved.current.quitDay, today.addDays(50));
      expect(await points(), hasLength(1));
    });

    test('both: the point and the plan', () async {
      await seedHabit(running, priceCents: 1000);
      final container = await open();
      final controller = container.read(editPlanProvider(1).notifier)
        ..setDailyLimit(5)
        ..setPriceText('14.50');

      expect(await controller.save(), isTrue);

      expect((await history()).plans, hasLength(2));
      expect((await points()).last.priceCents, 1450);
    });

    test('a habit with no cost starts a plan and writes no point', () async {
      await seedHabit(running, habit: Habit.socialMedia);
      final container = await open();
      final controller = container.read(editPlanProvider(1).notifier)
        ..setDailyLimit(5);

      expect(container.read(editPlanProvider(1)).priceChanged, isFalse);
      expect(await controller.save(), isTrue);

      expect((await history()).plans, hasLength(2));
      expect(await points(), isEmpty);
    });

    test('nothing changed: canSave is false and nothing is written', () async {
      await seedHabit(running, priceCents: 1000);
      final container = await open();
      final controller = container.read(editPlanProvider(1).notifier);

      final form = container.read(editPlanProvider(1));
      expect(form.currentLimit, 6);
      expect(form.storedPriceCents, 1000);
      expect(form.storedUnits, 20);
      expect(form.planChanged, isFalse);
      expect(form.priceChanged, isFalse);
      expect(form.canSave, isFalse);

      expect(await controller.save(), isFalse);

      expect((await history()).plans, hasLength(1));
      expect(await points(), hasLength(1));
    });

    test('changes put back count as nothing changed', () async {
      await seedHabit(running, priceCents: 1000);
      final container = await open();
      container.read(editPlanProvider(1).notifier)
        ..setDailyLimit(5)
        ..setDailyLimit(6)
        ..setPriceText('12')
        ..setPriceText('10');

      expect(container.read(editPlanProvider(1)).canSave, isFalse);
    });

    test('a plan past its quit date has changed from the start', () async {
      await seedHabit(
        PlanDraft(
          startDay: today.addDays(-40),
          startLimit: 9,
          quitDay: today.addDays(-5),
        ),
      );
      final container = await open();

      final form = container.read(editPlanProvider(1));
      expect(form.currentLimit, 0);
      expect(form.planChanged, isTrue);
      expect(form.canSave, isTrue);
    });
  });

  group('failures', () {
    test('an invalid price sets the error and saves nothing', () async {
      await seedHabit(running, priceCents: 1000);
      final container = await open();
      final controller = container.read(editPlanProvider(1).notifier)
        ..setDailyLimit(5)
        ..setPriceText('abc');

      expect(await controller.save(), isFalse);

      expect(
        container.read(editPlanProvider(1)).errorMessage,
        'Enter a valid price, or leave it empty.',
      );
      expect((await history()).plans, hasLength(1));
      expect(await points(), hasLength(1));
    });

    test('an invalid price with none stored can still be pressed', () async {
      await seedHabit(running);
      final container = await open();
      final controller = container.read(editPlanProvider(1).notifier)
        ..setPriceText('abc');

      expect(container.read(editPlanProvider(1)).canSave, isTrue);
      expect(await controller.save(), isFalse);
      expect(container.read(editPlanProvider(1)).errorMessage, isNotNull);
    });

    test('a failed plan keeps the price, and a retry saves one plan', () async {
      await seedHabit(running, priceCents: 1000);
      final failing = _FailFirstPlan(sl<SavePlan>());
      final container = await open(
        overrides: [savePlanProvider.overrideWithValue(failing)],
      );
      final controller = container.read(editPlanProvider(1).notifier)
        ..setDailyLimit(5)
        ..setPriceText('14.50');

      expect(await controller.save(), isFalse);

      final failed = container.read(editPlanProvider(1));
      expect(failed.errorMessage, isNotNull);
      expect(failed.isSubmitting, isFalse);
      expect((await stored()).priceCents, 1450);
      expect((await history()).plans, hasLength(1));

      expect(await controller.save(), isTrue);

      expect(failing.calls, 2);
      expect((await history()).plans, hasLength(2));
      expect(await points(), hasLength(2));
    });

    test('after a failed plan the old price counts as a change', () async {
      await seedHabit(running, priceCents: 1000);
      final container = await open(
        overrides: [
          savePlanProvider.overrideWithValue(_FailFirstPlan(sl<SavePlan>())),
        ],
      );
      final controller = container.read(editPlanProvider(1).notifier)
        ..setDailyLimit(5)
        ..setPriceText('14.50');
      await controller.save();

      expect(container.read(editPlanProvider(1)).priceChanged, isFalse);

      controller.setPriceText('10');
      final form = container.read(editPlanProvider(1));
      expect(form.storedPriceCents, 1450);
      expect(form.priceChanged, isTrue);
    });

    test('a failed price starts no plan', () async {
      await seedHabit(running, priceCents: 1000);
      final container = await open(
        overrides: [setHabitPriceProvider.overrideWithValue(_FailingPrice())],
      );
      final controller = container.read(editPlanProvider(1).notifier)
        ..setDailyLimit(5)
        ..setPriceText('14.50');

      expect(await controller.save(), isFalse);

      expect(container.read(editPlanProvider(1)).errorMessage, isNotNull);
      expect((await history()).plans, hasLength(1));
    });
  });

  test('two calls in one frame save once', () async {
    await seedHabit(running, priceCents: 1000);
    final container = await open();
    final controller = container.read(editPlanProvider(1).notifier)
      ..setDailyLimit(5)
      ..setPriceText('14.50');

    final results = await Future.wait([controller.save(), controller.save()]);

    expect(results, [isTrue, isFalse]);
    expect((await history()).plans, hasLength(2));
    expect(await points(), hasLength(2));
  });

  group('rulerSpanDays', () {
    test('is 119 by default', () async {
      await seedHabit(running);
      final container = await open();

      expect(container.read(editPlanProvider(1)).rulerSpanDays, 119);
    });

    test('reaches 4 weeks past a far quit date on opening', () async {
      await seedHabit(
        PlanDraft(startDay: today, startLimit: 9, quitDay: today.addDays(200)),
      );
      final container = await open();

      expect(container.read(editPlanProvider(1)).rulerSpanDays, 228);
    });

    test('a date on the wheel recomputes it', () async {
      await seedHabit(running);
      final container = await open();

      container
          .read(editPlanProvider(1).notifier)
          .setQuitDay(today.addDays(200));

      expect(container.read(editPlanProvider(1)).rulerSpanDays, 228);
    });

    test('a chip recomputes it, in both directions', () async {
      await seedHabit(running);
      final container = await open();
      final controller = container.read(editPlanProvider(1).notifier)
        ..selectQuitPreset(EditQuitPreset.weeks16);

      expect(container.read(editPlanProvider(1)).rulerSpanDays, 140);

      controller.selectQuitPreset(EditQuitPreset.weeks8);

      expect(container.read(editPlanProvider(1)).rulerSpanDays, 119);
    });

    test('the ruler never changes it', () async {
      await seedHabit(running);
      final container = await open();
      final controller = container.read(editPlanProvider(1).notifier)
        ..setQuitDay(today.addDays(200))
        ..setQuitDayFromRuler(today.addDays(20));

      final form = container.read(editPlanProvider(1));
      expect(form.quitDay, today.addDays(20));
      expect(form.quitPreset, isNull);
      expect(form.rulerSpanDays, 228);

      controller.setQuitDayFromRuler(today.addDays(227));

      expect(container.read(editPlanProvider(1)).rulerSpanDays, 228);
    });

    test('the ruler stops at tomorrow', () async {
      await seedHabit(running);
      final container = await open();
      container.read(editPlanProvider(1).notifier).setQuitDayFromRuler(today);

      expect(container.read(editPlanProvider(1)).quitDay, today.addDays(1));
    });
  });
}

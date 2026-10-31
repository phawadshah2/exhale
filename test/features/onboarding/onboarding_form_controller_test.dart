import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/domain/entities/habit_draft.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:exhale/features/habit/domain/repositories/habit_repository.dart';
import 'package:exhale/features/habit/domain/usecases/start_tracking.dart';
import 'package:exhale/features/onboarding/presentation/onboarding_copy.dart';
import 'package:exhale/features/onboarding/presentation/providers/onboarding_form_provider.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/plan/domain/repositories/plan_repository.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/repositories/settings_repository.dart';
import 'package:exhale/features/settings/domain/usecases/save_settings.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/pump_app.dart';

/// Reads like the real repository; every save fails.
class _FailingSaves implements SettingsRepository {
  _FailingSaves(this._inner);
  final SettingsRepository _inner;

  @override
  Stream<AppSettings> watch() => _inner.watch();

  @override
  Future<Result<AppSettings>> get() => _inner.get();

  @override
  Future<Result<void>> save(AppSettings settings) async =>
      const FailureResult<void>(StorageFailure());
}

void main() {
  late ProviderContainer container;

  // 02:00 on the 20th is still the 19th with a 4 AM reset.
  final today = LogicalDay(2026, 10, 19);

  ProviderContainer open({List<Override> overrides = const []}) =>
      ProviderContainer.test(
        overrides: [deviceRegionProvider.overrideWithValue('AE'), ...overrides],
      )..listen(onboardingFormProvider, (_, _) {});

  setUp(() async {
    await setUpTestDependencies(FixedClock(DateTime(2026, 10, 20, 2)));
    container = open();
  });

  tearDown(InjectionContainer.reset);

  OnboardingFormController controller() =>
      container.read(onboardingFormProvider.notifier);
  OnboardingFormState state() => container.read(onboardingFormProvider);

  test('starts today on vaping with the suggested quit date', () {
    expect(state().startDay, today);
    expect(state().habitKind, HabitKind.vaping);
    expect(state().startLimit, Habit.vaping.defaultDailyAmount);
    expect(state().unitsPerContainer, Habit.vaping.defaultUnitsPerContainer);
    expect(state().quitPreset, QuitPreset.suggested);
    expect(state().quitDay, today.addDays(12 * 7));
    expect(state().wakeMinute, 450);
    expect(state().bedMinute, 1410);
    expect(state().currency, 'AED');
  });

  test('an unknown region defaults to dollars', () {
    final other = ProviderContainer.test(
      overrides: [deviceRegionProvider.overrideWithValue(null)],
    );
    addTearDown(other.dispose);

    expect(other.read(onboardingFormProvider).currency, r'$');
  });

  test('presets are listed with Suggested first', () {
    expect(QuitPreset.values, [
      QuitPreset.suggested,
      QuitPreset.weeks4,
      QuitPreset.weeks8,
      QuitPreset.months3,
    ]);
  });

  test("picking a habit uses that habit's amounts", () {
    controller().selectHabit(HabitKind.smoking);
    expect(state().startLimit, 9);
    expect(state().unitsPerContainer, 20);
    expect(state().quitDay, today.addDays(63));
  });

  test('presets set the quit date from today', () {
    controller().selectQuitPreset(QuitPreset.weeks4);
    expect(state().quitDay, today.addDays(28));

    controller().selectQuitPreset(QuitPreset.months3);
    expect(state().quitDay, today.addDays(91));
  });

  test('Suggested follows the daily amount', () {
    controller().setStartLimit(10);
    expect(state().quitDay, today.addDays(70));

    controller().setStartLimit(80);
    expect(state().quitDay, today.addDays(90));
  });

  test('any later quit date is kept; earlier ones move after today', () {
    controller().setQuitDay(LogicalDay(2026, 12, 1));
    expect(state().quitPreset, isNull);
    expect(state().quitDay, LogicalDay(2026, 12, 1));

    controller().setStartLimit(4);
    expect(state().quitDay, LogicalDay(2026, 12, 1));

    controller().setQuitDay(today);
    expect(state().quitDay, today.addDays(1));
  });

  test('flags a steep plan', () {
    controller().setQuitDay(today.addDays(5));
    expect(state().isSteep, isTrue);

    controller().selectQuitPreset(QuitPreset.weeks4);
    expect(state().isSteep, isFalse);
  });

  group('steps', () {
    test('a habit with cost has six steps', () {
      controller().selectHabit(HabitKind.smoking);

      expect(state().steps, OnboardingStep.values);
      expect(state().total, 6);
      expect(state().stepLabel(OnboardingStep.welcome), '1/6');
      expect(state().stepLabel(OnboardingStep.day), '5/6');
    });

    test('a habit without cost skips the cost step', () {
      controller().selectHabit(HabitKind.socialMedia);

      expect(state().steps, isNot(contains(OnboardingStep.cost)));
      expect(state().total, 5);
      expect(state().stepLabel(OnboardingStep.day), '4/5');
      expect(state().stepLabel(OnboardingStep.deal), '5/5');
    });
  });

  test('one dot per unit up to 12, then each dot stands for more', () {
    controller().setStartLimit(12);
    expect((state().dotUnit, state().dotCount), (1, 12));

    controller().setStartLimit(13);
    expect((state().dotUnit, state().dotCount), (2, 7));

    controller().setStartLimit(80);
    expect((state().dotUnit, state().dotCount), (7, 12));
  });

  test('monthly and yearly cost from the pack price', () {
    controller()
      ..selectHabit(HabitKind.smoking)
      ..setPriceText('14.50')
      ..setUnitsPerContainer(20)
      ..setStartLimit(10);

    expect(state().monthlyCostCents, 21750);
    expect(state().yearlyCostCents, 264625);
  });

  test('skipping the price clears it and its error', () {
    controller()
      ..selectHabit(HabitKind.smoking)
      ..setPriceText('abc');
    expect(state().hasInvalidPrice, isTrue);

    controller().skipPrice();

    expect(state().priceText, isEmpty);
    expect(state().hasInvalidPrice, isFalse);
    expect(state().monthlyCostCents, isNull);
    expect(state().yearlyCostCents, isNull);
  });

  test('a day under 4 hours is ignored', () {
    controller().setDayWindow(wakeMinute: 1380, bedMinute: 120);
    expect((state().wakeMinute, state().bedMinute), (450, 1410));

    controller().setDayWindow(wakeMinute: 420, bedMinute: 60);
    expect((state().wakeMinute, state().bedMinute), (420, 60));
  });

  test('pace spreads the limit across the waking day', () {
    controller().setStartLimit(12);
    expect(state().paceMinutes, 80);

    controller().setStartLimit(80);
    expect(state().paceMinutes, 12);
  });

  test("tomorrow's limit comes from the plan", () {
    controller()
      ..setStartLimit(10)
      ..setQuitDay(today.addDays(5));

    expect(state().tomorrowLimit, 8);
  });

  test('an invalid price blocks submit', () async {
    controller()
      ..selectHabit(HabitKind.smoking)
      ..setPriceText('abc');

    expect(await controller().submit(), isFalse);
    expect(state().errorMessage, contains('valid price'));
  });

  group('copy', () {
    test('amount reactions by share of a normal day', () {
      String reaction(int amount) =>
          OnboardingCopy.amountReaction(amount: amount, typical: 5);

      expect(reaction(2), 'Practically a hobby.');
      expect(reaction(5), 'Respectable. For now.');
      expect(reaction(10), "That's not a habit. That's a part-time job.");
      expect(reaction(11), "That's a full-time job with overtime.");
    });

    test('every habit gets its own reply', () {
      final replies = HabitKind.values.map(OnboardingCopy.habitReply).toSet();

      expect(replies, hasLength(HabitKind.values.length));
      expect(replies, everyElement(isNotEmpty));
      expect(
        OnboardingCopy.habitReply(HabitKind.vaping),
        'Ah. The USB stick you inhale.',
      );
    });
  });

  Future<TrackedHabit> onlyHabit() async {
    final habits =
        (await sl<HabitRepository>().getActive() as Success<List<TrackedHabit>>)
            .value;
    return habits.single;
  }

  Future<AppSettings> storedSettings() async =>
      (await sl<SettingsRepository>().get() as Success<AppSettings>).value;

  test(
    'submit saves the day and currency, then habit 1 and its plan',
    () async {
      await sl<SettingsRepository>().save(
        (await storedSettings()).copyWith(userName: () => 'Fawad'),
      );
      controller()
        ..setStartLimit(12)
        ..selectQuitPreset(QuitPreset.weeks8)
        ..setCurrency('€')
        ..setPriceText('14.50')
        ..setUnitsPerContainer(25)
        ..setDayWindow(wakeMinute: 420, bedMinute: 60);

      expect(await controller().submit(), isTrue);

      final settings = await storedSettings();
      expect(settings.wakeMinute, 420);
      expect(settings.bedMinute, 60);
      expect(settings.currencySymbol, '€');
      expect(settings.userName, 'Fawad');

      final habit = await onlyHabit();
      expect(habit.id, 1);
      expect(habit.habit, Habit.vaping);
      expect(habit.priceCents, 1450);
      expect(habit.unitsPerContainer, 25);
      expect(habit.reason, isNull);

      final history = (await sl<PlanRepository>().getHistory(
        habit.id,
      ) as Success<PlanHistory?>).value!;
      expect(
        history.current,
        ReductionPlan(
          startDay: today,
          startLimit: 12,
          quitDay: today.addDays(56),
        ),
      );
    },
  );

  test('submit saves a custom habit', () async {
    controller()
      ..selectHabit(HabitKind.custom)
      ..setCustomName(' Gaming ')
      ..setCustomUnit('Match');

    expect(await controller().submit(), isTrue);

    final habit = await onlyHabit();
    expect(habit.habit.kind, HabitKind.custom);
    expect(habit.habit.name, 'Gaming');
    expect(habit.habit.unit, 'match');
  });

  test('a price left from a habit with cost does not count after a switch', () {
    controller()
      ..selectHabit(HabitKind.smoking)
      ..setPriceText('abc')
      ..selectHabit(HabitKind.socialMedia);

    expect(state().hasInvalidPrice, isFalse);

    controller()
      ..selectHabit(HabitKind.smoking)
      ..setPriceText('14.50')
      ..selectHabit(HabitKind.socialMedia);

    expect(state().yearlyCostCents, isNull);
  });

  test('a habit without cost stores no price', () async {
    controller()
      ..selectHabit(HabitKind.socialMedia)
      ..setPriceText('5.00');

    expect(await controller().submit(), isTrue);

    expect((await onlyHabit()).priceCents, isNull);
  });

  test('a second submit adds no second habit', () async {
    expect(await controller().submit(), isTrue);
    controller().selectHabit(HabitKind.caffeine);

    expect(await controller().submit(), isTrue);

    expect((await onlyHabit()).habit, Habit.vaping);
  });

  test('a failed save keeps every answer and shows the error', () async {
    container = open(
      overrides: [
        saveSettingsProvider.overrideWithValue(
          SaveSettings(_FailingSaves(sl<SettingsRepository>())),
        ),
      ],
    );
    controller()
      ..selectHabit(HabitKind.smoking)
      ..setStartLimit(10)
      ..setPriceText('14.50')
      ..setDayWindow(wakeMinute: 420, bedMinute: 60);

    expect(await controller().submit(), isFalse);

    expect(state().errorMessage, isNotNull);
    expect(state().isSubmitting, isFalse);
    expect(state().habitKind, HabitKind.smoking);
    expect(state().startLimit, 10);
    expect(state().priceText, '14.50');
    expect((state().wakeMinute, state().bedMinute), (420, 60));
    final habits = await sl<HabitRepository>().getActive();
    expect((habits as Success<List<TrackedHabit>>).value, isEmpty);
  });

  group('adding a habit', () {
    List<Override> adding({List<Override> more = const []}) => [
      onboardingModeProvider.overrideWithValue(OnboardingMode.addHabit),
      ...more,
    ];

    test('steps skip Welcome and Your day', () {
      container = open(overrides: adding());

      expect(state().steps, [
        OnboardingStep.habit,
        OnboardingStep.amount,
        OnboardingStep.cost,
        OnboardingStep.deal,
      ]);

      controller().selectHabit(HabitKind.socialMedia);

      expect(state().steps, [
        OnboardingStep.habit,
        OnboardingStep.amount,
        OnboardingStep.deal,
      ]);
    });

    test(
      'submit adds beside the current habit without saving settings',
      () async {
        await sl<StartTracking>()((
          habit: const HabitDraft(habit: Habit.vaping),
          plan: PlanDraft(
            startDay: today,
            startLimit: 10,
            quitDay: today.addDays(70),
          ),
        ));
        container = open(
          overrides: adding(
            more: [
              saveSettingsProvider.overrideWithValue(
                SaveSettings(_FailingSaves(sl<SettingsRepository>())),
              ),
            ],
          ),
        );
        controller().selectHabit(HabitKind.smoking);

        expect(await controller().submit(), isTrue);

        expect(state().errorMessage, isNull);
        final habits = await sl<HabitRepository>().getActive();
        expect(
          (habits as Success<List<TrackedHabit>>).value.map((h) => h.habit),
          [Habit.vaping, Habit.smoking],
        );
      },
    );
  });
}

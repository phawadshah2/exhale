import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:exhale/features/habit/domain/repositories/habit_repository.dart';
import 'package:exhale/features/onboarding/presentation/providers/setup_form_provider.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:exhale/features/plan/domain/repositories/plan_repository.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/pump_app.dart';

void main() {
  late ProviderContainer container;

  // 02:00 on the 20th is still the 19th with a 4 AM reset.
  final today = LogicalDay(2026, 10, 19);

  setUp(() async {
    await setUpTestDependencies(FixedClock(DateTime(2026, 10, 20, 2)));
    container = ProviderContainer.test()..listen(setupFormProvider, (_, _) {});
  });

  tearDown(InjectionContainer.reset);

  SetupFormController controller() =>
      container.read(setupFormProvider.notifier);
  SetupFormState state() => container.read(setupFormProvider);

  test('starts today on vaping with the suggested quit date', () {
    expect(state().startDay, today);
    expect(state().habitKind, HabitKind.vaping);
    expect(state().startLimit, Habit.vaping.defaultDailyAmount);
    expect(state().unitsPerContainer, Habit.vaping.defaultUnitsPerContainer);
    expect(state().quitPreset, QuitPreset.suggested);
    expect(state().quitDay, today.addDays(12 * 7));
    expect(state().preview!.daysPerDrop, 7);
  });

  test("picking a habit uses that habit's amounts", () {
    controller().selectHabit(HabitKind.smoking);
    expect(state().startLimit, 9);
    expect(state().unitsPerContainer, 20);
    expect(state().quitDay, today.addDays(63));
  });

  test('presets set the quit date from the start day', () {
    controller().selectQuitPreset(QuitPreset.weeks4);
    expect(state().quitDay, today.addDays(28));

    controller().selectQuitPreset(QuitPreset.months3);
    expect(state().quitDay, today.addDays(91));
  });

  test('a preset follows changes to the start day and daily amount', () {
    controller()
      ..setStartDay(today.addDays(2))
      ..setStartLimit(10);
    expect(state().quitDay, today.addDays(2 + 70));

    controller()
      ..selectQuitPreset(QuitPreset.weeks8)
      ..setStartDay(today.addDays(5));
    expect(state().quitDay, today.addDays(5 + 56));
  });

  test('any later quit date is kept; earlier ones move after the start', () {
    controller().setQuitDay(LogicalDay(2026, 12, 1));
    expect(state().quitPreset, isNull);
    expect(state().quitDay, LogicalDay(2026, 12, 1));

    controller().setStartLimit(4);
    expect(state().quitDay, LogicalDay(2026, 12, 1));

    controller().setQuitDay(today);
    expect(state().quitDay, today.addDays(1));

    controller().setQuitDay(today.addDays(2000));
    expect(state().quitDay, today.addDays(2000));
    expect(state().preview, isNotNull);
  });

  test('moving the start past a picked quit date pushes it out', () {
    controller()
      ..setQuitDay(today.addDays(10))
      ..setStartDay(today.addDays(20));

    expect(state().quitDay, today.addDays(21));
  });

  test('flags a steep plan', () {
    controller().setQuitDay(today.addDays(5));
    expect(state().isSteep, isTrue);

    controller().selectQuitPreset(QuitPreset.weeks4);
    expect(state().isSteep, isFalse);
  });

  test('an invalid pack price blocks submit', () async {
    controller().setPriceText('abc');

    expect(await controller().submit(), isFalse);
    expect(state().errorMessage, contains('valid price'));
  });

  Future<TrackedHabit> onlyHabit() async {
    final habits =
        (await sl<HabitRepository>().getActive() as Success<List<TrackedHabit>>)
            .value;
    return habits.single;
  }

  test('submit saves the name, then habit 1 and its plan', () async {
    controller()
      ..setName('  Fawad ')
      ..setStartLimit(12)
      ..selectQuitPreset(QuitPreset.weeks8)
      ..setPriceText('14.50')
      ..setUnitsPerContainer(25);

    expect(await controller().submit(), isTrue);

    final settings =
        (await sl<SettingsRepository>().get() as Success<AppSettings>).value;
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
  });

  test('submit saves a custom habit and the reason', () async {
    controller()
      ..selectHabit(HabitKind.custom)
      ..setCustomName(' Gaming ')
      ..setCustomUnit('Match')
      ..setReason('  More time with family ');

    expect(await controller().submit(), isTrue);

    final habit = await onlyHabit();
    expect(habit.habit.kind, HabitKind.custom);
    expect(habit.habit.name, 'Gaming');
    expect(habit.habit.unit, 'match');
    expect(habit.reason, 'More time with family');
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
}

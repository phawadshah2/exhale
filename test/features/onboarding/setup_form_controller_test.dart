import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
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

  test('starts today with the suggested quit date', () {
    expect(state().startDay, today);
    expect(state().startLimit, 9);
    expect(state().quitPreset, QuitPreset.suggested);
    expect(state().quitDay, today.addDays(63));
    expect(state().preview!.daysPerDrop, 7);
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
      ..setStartLimit(12);
    expect(state().quitDay, today.addDays(2 + 84));

    controller()
      ..selectQuitPreset(QuitPreset.weeks8)
      ..setStartDay(today.addDays(5));
    expect(state().quitDay, today.addDays(5 + 56));
  });

  test('a picked date is kept, but clamped into 3–365 days', () {
    controller().setQuitDay(LogicalDay(2026, 12, 1));
    expect(state().quitPreset, isNull);
    expect(state().quitDay, LogicalDay(2026, 12, 1));

    controller().setStartLimit(4);
    expect(state().quitDay, LogicalDay(2026, 12, 1));

    controller().setQuitDay(today.addDays(1));
    expect(state().quitDay, today.addDays(3));

    controller().setQuitDay(today.addDays(500));
    expect(state().quitDay, today.addDays(365));
  });

  test('moving the start past a picked quit date pushes it out', () {
    controller()
      ..setQuitDay(today.addDays(10))
      ..setStartDay(today.addDays(20));

    expect(state().quitDay, today.addDays(23));
  });

  test('flags a steep plan', () {
    controller().setQuitDay(today.addDays(5));
    expect(state().isSteep, isTrue);

    controller().selectQuitPreset(QuitPreset.weeks4);
    expect(state().isSteep, isFalse);
  });

  test('an invalid pack price blocks submit', () async {
    controller().setPackPriceText('abc');

    expect(await controller().submit(), isFalse);
    expect(state().errorMessage, contains('pack price'));
  });

  test('submit saves settings and the plan', () async {
    controller()
      ..setName('  Fawad ')
      ..setStartLimit(12)
      ..selectQuitPreset(QuitPreset.weeks8)
      ..setPackPriceText('14.50')
      ..setCigarettesPerPack(25);

    expect(await controller().submit(), isTrue);

    final settings =
        (await sl<SettingsRepository>().get() as Success<AppSettings>).value;
    final history =
        (await sl<PlanRepository>().getHistory() as Success<PlanHistory?>)
            .value!;
    expect(settings.userName, 'Fawad');
    expect(settings.packPriceCents, 1450);
    expect(settings.cigarettesPerPack, 25);
    expect(
      history.current,
      ReductionPlan(
        startDay: today,
        startLimit: 12,
        quitDay: today.addDays(56),
      ),
    );
  });
}

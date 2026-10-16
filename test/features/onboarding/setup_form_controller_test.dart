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

  setUp(() async {
    await setUpTestDependencies(FixedClock(DateTime(2026, 10, 16, 2)));
    container = ProviderContainer.test()..listen(setupFormProvider, (_, _) {});
  });

  tearDown(InjectionContainer.reset);

  SetupFormController controller() =>
      container.read(setupFormProvider.notifier);
  SetupFormState state() => container.read(setupFormProvider);

  test('starts on the logical day, with design defaults', () {
    // 02:00 on the 16th is still the 15th with a 4 AM reset.
    expect(state().startDay, LogicalDay(2026, 10, 15));
    expect(state().startLimit, 9);
    expect(state().stepDays, 7);
    expect(state().targetLimit, 0);
    expect(state().preview!.targetDay, LogicalDay(2026, 12, 17));
  });

  test('clamps steppers to valid ranges', () {
    controller()
      ..setStartLimit(0)
      ..setStepDays(99);

    expect(state().startLimit, 1);
    expect(state().stepDays, 30);
  });

  test('custom target stays below the start limit', () {
    controller()
      ..setQuitCompletely(quitCompletely: false)
      ..setCustomTarget(20);
    expect(state().targetLimit, 8);

    controller().setStartLimit(5);
    expect(state().targetLimit, 4);
  });

  test('a start limit of 1 forces quitting completely', () {
    controller()
      ..setQuitCompletely(quitCompletely: false)
      ..setStartLimit(1);

    expect(state().quitCompletely, isTrue);
    controller().setQuitCompletely(quitCompletely: false);
    expect(state().quitCompletely, isTrue);
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
      ReductionPlan(startDay: LogicalDay(2026, 10, 15), startLimit: 12),
    );
  });
}

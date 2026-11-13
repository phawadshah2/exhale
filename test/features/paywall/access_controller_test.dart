import 'package:exhale/app/app.dart';
import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/paywall/data/fake/fake_store_repository.dart';
import 'package:exhale/features/paywall/domain/entities/access.dart';
import 'package:exhale/features/paywall/domain/entities/plan_kind.dart';
import 'package:exhale/features/paywall/presentation/providers/paywall_providers.dart';
import 'package:exhale/features/plan/domain/entities/plan_draft.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/pump_app.dart';

void main() {
  final now = DateTime(2026, 11, 13, 9);
  late FakeStoreRepository store;

  setUp(() async {
    store = FakeStoreRepository();
    await setUpTestDependencies(FixedClock(now), store: store);
  });

  tearDown(InjectionContainer.reset);

  ProviderContainer container({Access initial = const NeverPaid()}) {
    final container = ProviderContainer(
      overrides: [initialAccessProvider.overrideWithValue(initial)],
    );
    addTearDown(container.dispose);
    container.listen(accessProvider, (_, _) {});
    return container;
  }

  Future<AppSettings> savedSettings() async =>
      (await sl<SettingsRepository>().get() as Success<AppSettings>).value;

  test('starts from the access read at startup', () {
    const lifetime = Entitled(
      plan: PlanKind.lifetime,
      expiresAt: null,
      inTrial: false,
    );

    expect(container(initial: lifetime).read(accessProvider), lifetime);
  });

  test('an unknown access at startup asks the store again', () async {
    store.access = const Entitled(
      plan: PlanKind.lifetime,
      expiresAt: null,
      inTrial: false,
    );
    final scope = container(initial: const AccessUnknown());

    expect(scope.read(accessProvider), const AccessUnknown());
    await pumpEventQueue();

    expect(
      scope.read(accessProvider),
      const Entitled(plan: PlanKind.lifetime, expiresAt: null, inTrial: false),
    );
    expect((await savedSettings()).accessState, 'entitled');
  });

  test('a known access at startup does not ask the store again', () async {
    store.access = const Entitled(
      plan: PlanKind.lifetime,
      expiresAt: null,
      inTrial: false,
    );
    final scope = container();
    await pumpEventQueue();

    expect(scope.read(accessProvider), const NeverPaid());
  });

  test('a store change is followed, and the access is cached', () async {
    final scope = container();
    final expires = now.add(const Duration(days: 30));
    store
      ..access = Entitled(
        plan: PlanKind.monthly,
        expiresAt: expires,
        inTrial: false,
      )
      ..emitChange();
    await pumpEventQueue();

    expect(
      scope.read(accessProvider),
      Entitled(plan: PlanKind.monthly, expiresAt: expires, inTrial: false),
    );
    final saved = await savedSettings();
    expect(saved.accessState, 'entitled');
    expect(saved.accessPlan, 'monthly');
    expect(saved.accessUntil, expires);
  });

  test('a lapse arriving as a change is followed', () async {
    final scope = container(
      initial: const Entitled(
        plan: PlanKind.annual,
        expiresAt: null,
        inTrial: false,
      ),
    );
    store
      ..access = Lapsed(plan: PlanKind.annual, endedAt: now)
      ..emitChange();
    await pumpEventQueue();

    expect(
      scope.read(accessProvider),
      Lapsed(plan: PlanKind.annual, endedAt: now),
    );
    expect((await savedSettings()).accessState, 'lapsed');
  });

  test('refresh with the store unreachable keeps the state', () async {
    const lifetime = Entitled(
      plan: PlanKind.lifetime,
      expiresAt: null,
      inTrial: false,
    );
    final scope = container(initial: lifetime);
    store.offline = true;

    await scope.read(accessProvider.notifier).refresh();

    expect(scope.read(accessProvider), lifetime);
    expect((await savedSettings()).accessState, isNull);
  });

  test('refresh with the store unreachable uses a usable cache', () async {
    await sl<SettingsRepository>().save(
      const AppSettings(accessState: 'entitled', accessPlan: 'lifetime'),
    );
    final scope = container();
    store.offline = true;

    await scope.read(accessProvider.notifier).refresh();

    expect(
      scope.read(accessProvider),
      const Entitled(plan: PlanKind.lifetime, expiresAt: null, inTrial: false),
    );
  });

  test('an unchanged access is not saved again', () async {
    await sl<SettingsRepository>().save(
      const AppSettings(userName: 'Sam', accessState: 'neverPaid'),
    );
    final scope = container();
    final before = await savedSettings();

    await scope.read(accessProvider.notifier).refresh();

    expect(await savedSettings(), before);
  });

  group('offersProvider', () {
    test('loads the three offers', () async {
      final offers = container().listen(offersProvider.future, (_, _) {});

      expect(await offers.read(), FakeStoreRepository.defaultOffers);
    });

    test('fails when the store cannot be reached', () async {
      store.offline = true;
      final offers = container().listen(offersProvider.future, (_, _) {});

      await expectLater(offers.read(), throwsA(isA<OffersUnavailable>()));
    });
  });

  testWidgets('a return to the foreground refreshes access', (tester) async {
    store.access = const Entitled(
      plan: PlanKind.lifetime,
      expiresAt: null,
      inTrial: false,
    );
    await seedHabit(
      PlanDraft(
        startDay: LogicalDay(2026, 11, 13),
        startLimit: 5,
        quitDay: LogicalDay(2026, 11, 13).addDays(30),
      ),
    );
    await tester.pumpAppPastSplash(height: 2400);
    final scope = ProviderScope.containerOf(
      tester.element(find.byType(ExhaleApp)),
    );
    store.access = Lapsed(plan: PlanKind.annual, endedAt: now);

    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
      ..handleAppLifecycleStateChanged(AppLifecycleState.paused)
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.runAsync(pumpEventQueue);
    await tester.pump();

    expect(
      scope.read(accessProvider),
      Lapsed(plan: PlanKind.annual, endedAt: now),
    );

    await tester.disposeApp();
  });
}

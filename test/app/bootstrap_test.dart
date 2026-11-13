import 'dart:async';

import 'package:exhale/app/bootstrap.dart';
import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/features/paywall/data/fake/fake_store_repository.dart';
import 'package:exhale/features/paywall/domain/entities/access.dart';
import 'package:exhale/features/paywall/domain/entities/plan_kind.dart';
import 'package:exhale/features/paywall/presentation/providers/paywall_providers.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixed_clock.dart';
import '../helpers/pump_app.dart';

/// A store that never answers about access.
class _SilentStore extends FakeStoreRepository {
  @override
  Future<Result<Access>> currentAccess() => Completer<Result<Access>>().future;
}

const _cachedLifetime = AppSettings(
  accessState: 'entitled',
  accessPlan: 'lifetime',
);

const _lifetime = Entitled(
  plan: PlanKind.lifetime,
  expiresAt: null,
  inTrial: false,
);

Access _initialAccess(List<Override> overrides) {
  final container = ProviderContainer(overrides: overrides);
  addTearDown(container.dispose);
  return container.read(initialAccessProvider);
}

void main() {
  final clock = FixedClock(DateTime(2026, 11, 13, 9));

  tearDown(InjectionContainer.reset);

  test('the store gets 3 s at startup', () {
    expect(startupStoreTimeout, const Duration(seconds: 3));
  });

  test('a silent store falls back to the cache in time', () async {
    await setUpTestDependencies(clock, store: _SilentStore());
    await sl<SettingsRepository>().save(_cachedLifetime);

    final watch = Stopwatch()..start();
    final overrides = await startupOverrides(
      storeTimeout: const Duration(milliseconds: 100),
    );

    expect(watch.elapsed, lessThan(const Duration(seconds: 1)));
    expect(_initialAccess(overrides), _lifetime);
  });

  test('a silent store with nothing cached is unknown', () async {
    await setUpTestDependencies(clock, store: _SilentStore());

    final overrides = await startupOverrides(
      storeTimeout: const Duration(milliseconds: 100),
    );

    expect(_initialAccess(overrides), const AccessUnknown());
  });

  test('a store failure with a cached Lifetime is Entitled', () async {
    await setUpTestDependencies(
      clock,
      store: FakeStoreRepository(offline: true),
    );
    await sl<SettingsRepository>().save(_cachedLifetime);

    expect(_initialAccess(await startupOverrides()), _lifetime);
  });

  test('a store answer wins over the cache', () async {
    await setUpTestDependencies(clock, store: FakeStoreRepository());
    await sl<SettingsRepository>().save(_cachedLifetime);

    expect(_initialAccess(await startupOverrides()), const NeverPaid());
  });
}

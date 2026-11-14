import 'dart:async';

import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/clock.dart';
import 'package:exhale/features/paywall/domain/entities/access.dart';
import 'package:exhale/features/paywall/domain/repositories/store_repository.dart';
import 'package:exhale/features/paywall/domain/services/access_cache.dart';
import 'package:exhale/features/paywall/presentation/providers/paywall_providers.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/repositories/settings_repository.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter_riverpod/misc.dart';

/// How long the first frame waits for the App Store.
const Duration startupStoreTimeout = Duration(seconds: 3);

/// Provider overrides that need storage, or the store, before the first frame.
Future<List<Override>> startupOverrides({
  Duration storeTimeout = startupStoreTimeout,
}) async {
  final repository = sl<SettingsRepository>();
  var settings = switch (await repository.get()) {
    Success(:final value) => value,
    FailureResult() => const AppSettings(),
  };
  final live = switch (await sl<StoreRepository>().currentAccess().timeout(
    storeTimeout,
    onTimeout: () => const FailureResult(StoreFailure()),
  )) {
    Success(:final value) => value,
    FailureResult() => const AccessUnknown(),
  };
  // Cached now, so a later offline start knows about a purchase made
  // elsewhere.
  final cached = withCachedAccess(settings, live);
  if (cached != settings && await repository.save(cached) is Success) {
    settings = cached;
  }
  final access = effectiveAccess(live, settings, sl<Clock>().now());
  return [
    initialSettingsProvider.overrideWithValue(settings),
    initialAccessProvider.overrideWithValue(access),
  ];
}

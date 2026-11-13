import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/presentation/providers/clock_providers.dart';
import 'package:exhale/features/paywall/domain/entities/access.dart';
import 'package:exhale/features/paywall/domain/entities/offer.dart';
import 'package:exhale/features/paywall/domain/repositories/store_repository.dart';
import 'package:exhale/features/paywall/domain/services/access_cache.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final storeRepositoryProvider = Provider<StoreRepository>(
  (ref) => sl<StoreRepository>(),
);

/// Access read before the first frame; `startupOverrides()` overrides it.
final initialAccessProvider = Provider<Access>(
  (ref) => throw UnimplementedError('Overridden by startupOverrides()'),
);

final accessProvider = NotifierProvider<AccessController, Access>(
  AccessController.new,
);

class AccessController extends Notifier<Access> {
  @override
  Access build() {
    final subscription = ref
        .watch(storeRepositoryProvider)
        .changes
        .listen((_) => refresh());
    ref.onDispose(subscription.cancel);
    return ref.watch(initialAccessProvider);
  }

  /// Asks the store again. A known answer replaces the state and the cache;
  /// when the store cannot answer, a usable cache replaces the state and
  /// otherwise it stays as it is.
  Future<void> refresh() async {
    final live = switch (await ref
        .read(storeRepositoryProvider)
        .currentAccess()) {
      Success(:final value) => value,
      FailureResult() => const AccessUnknown(),
    };
    if (!ref.mounted) return;
    final settings = switch (await ref.read(settingsRepositoryProvider).get()) {
      Success(:final value) => value,
      FailureResult() => ref.read(currentSettingsProvider),
    };
    if (!ref.mounted) return;
    final access = effectiveAccess(
      live,
      settings,
      ref.read(clockProvider).now(),
    );
    if (access is! AccessUnknown) state = access;
    if (live is! AccessUnknown &&
        withCachedAccess(settings, live) != settings) {
      await ref
          .read(settingsActionsProvider)
          .update((current) => withCachedAccess(current, live));
    }
  }
}

/// The store could not load the offers.
class OffersUnavailable implements Exception {
  const OffersUnavailable();
}

/// Annual, Monthly and Lifetime; fails with [OffersUnavailable]. No automatic
/// retry: the paywall's "Try again" invalidates it.
final FutureProvider<List<Offer>> offersProvider =
    FutureProvider.autoDispose<List<Offer>>(
      (ref) async =>
          switch (await ref.watch(storeRepositoryProvider).loadOffers()) {
            Success(:final value) => value,
            FailureResult() => throw const OffersUnavailable(),
          },
      retry: (_, _) => null,
    );

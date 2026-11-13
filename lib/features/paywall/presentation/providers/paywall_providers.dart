import 'dart:async';

import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/presentation/providers/clock_providers.dart';
import 'package:exhale/features/paywall/domain/entities/access.dart';
import 'package:exhale/features/paywall/domain/entities/offer.dart';
import 'package:exhale/features/paywall/domain/entities/plan_kind.dart';
import 'package:exhale/features/paywall/domain/entities/purchase_outcome.dart';
import 'package:exhale/features/paywall/domain/repositories/store_repository.dart';
import 'package:exhale/features/paywall/domain/services/access_cache.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

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
    final initial = ref.watch(initialAccessProvider);
    // The store did not answer at startup and nothing was cached: ask again
    // rather than wait for a resume.
    if (initial is AccessUnknown) {
      unawaited(Future.microtask(() => ref.mounted ? refresh() : null));
    }
    return initial;
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

@immutable
class PaywallState {
  const PaywallState({this.selected = PlanKind.annual, this.busy = false});

  final PlanKind selected;

  /// A purchase or restore is under way.
  final bool busy;

  PaywallState copyWith({PlanKind? selected, bool? busy}) => PaywallState(
    selected: selected ?? this.selected,
    busy: busy ?? this.busy,
  );

  @override
  bool operator ==(Object other) =>
      other is PaywallState && other.selected == selected && other.busy == busy;

  @override
  int get hashCode => Object.hash(selected, busy);
}

final NotifierProvider<PaywallController, PaywallState>
paywallControllerProvider =
    NotifierProvider.autoDispose<PaywallController, PaywallState>(
      PaywallController.new,
    );

class PaywallController extends Notifier<PaywallState> {
  @override
  PaywallState build() => const PaywallState();

  void select(PlanKind plan) {
    if (!state.busy) state = state.copyWith(selected: plan);
  }

  /// Buys the selected plan. Null when the store failed, or while another
  /// call is under way. A purchase refreshes access before it returns.
  Future<PurchaseOutcome?> buy() async {
    if (state.busy) return null;
    state = state.copyWith(busy: true);
    // Kept while the sheet is up: a purchase can take the page away.
    final link = ref.keepAlive();
    try {
      final outcome = switch (await ref
          .read(storeRepositoryProvider)
          .purchase(state.selected)) {
        Success(:final value) => value,
        FailureResult() => null,
      };
      if (outcome == PurchaseOutcome.purchased) {
        await ref.read(accessProvider.notifier).refresh();
      }
      return outcome;
    } finally {
      state = state.copyWith(busy: false);
      link.close();
    }
  }

  /// Restores purchases and re-checks access; true when it is now entitled,
  /// false when the store could not restore.
  Future<bool> restore() async {
    if (state.busy) return false;
    state = state.copyWith(busy: true);
    final link = ref.keepAlive();
    try {
      if (await ref.read(storeRepositoryProvider).restore() is! Success) {
        return false;
      }
      await ref.read(accessProvider.notifier).refresh();
      return ref.read(accessProvider) is Entitled;
    } finally {
      state = state.copyWith(busy: false);
      link.close();
    }
  }
}

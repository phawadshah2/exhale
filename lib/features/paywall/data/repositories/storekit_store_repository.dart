import 'dart:async';

import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/features/paywall/data/storekit/storekit_gateway.dart';
import 'package:exhale/features/paywall/domain/entities/access.dart';
import 'package:exhale/features/paywall/domain/entities/offer.dart';
import 'package:exhale/features/paywall/domain/entities/plan_kind.dart';
import 'package:exhale/features/paywall/domain/entities/purchase_outcome.dart';
import 'package:exhale/features/paywall/domain/entities/store_transaction.dart';
import 'package:exhale/features/paywall/domain/repositories/store_repository.dart';
import 'package:exhale/features/paywall/domain/services/access_resolver.dart';

class StoreKitStoreRepository implements StoreRepository {
  StoreKitStoreRepository(this._gateway, {this.timeout = defaultTimeout});

  static const Duration defaultTimeout = Duration(seconds: 10);

  final StoreKitGateway _gateway;

  /// For calls that show no sheet; a purchase, restore or manage call waits
  /// for the user.
  final Duration timeout;

  @override
  Future<Result<List<Offer>>> loadOffers() => _guard(() async {
    final ids = [for (final plan in PlanKind.values) plan.productId];
    final products = {
      for (final product in await _gateway.products(ids)) product.id: product,
    };
    if (!ids.every(products.containsKey)) return _failure();
    final trialEligible = await _gateway.isIntroEligible(
      PlanKind.annual.productId,
    );
    return Success([
      for (final plan in PlanKind.values)
        _offer(plan, products[plan.productId]!, trialEligible: trialEligible),
    ]);
  }, timed: true);

  @override
  Future<Result<Access>> currentAccess() => _guard(() async {
    final current = await _gateway.currentEntitlements();
    final history = await _gateway.transactions();
    return Success(
      resolveAccess(current: _ours(current), history: _ours(history)),
    );
  }, timed: true);

  @override
  Future<Result<PurchaseOutcome>> purchase(PlanKind plan) => _guard(() async {
    switch (await _gateway.purchase(plan.productId)) {
      case SK2ProductPurchaseResult.success:
        await _finishUnfinished();
        return const Success(PurchaseOutcome.purchased);
      case SK2ProductPurchaseResult.userCancelled:
        return const Success(PurchaseOutcome.cancelled);
      case SK2ProductPurchaseResult.pending:
        return const Success(PurchaseOutcome.pending);
      case SK2ProductPurchaseResult.unverified:
        return _failure();
    }
  });

  @override
  Future<Result<void>> restore() => _guard(() async {
    await _gateway.sync();
    return const Success(null);
  });

  @override
  Future<Result<void>> manageSubscriptions() => _guard(() async {
    await _gateway.showManageSubscriptions();
    return const Success(null);
  });

  @override
  late final Stream<void> changes = _gateway.updates.asyncMap((_) async {
    try {
      await _finishUnfinished();
    } on Exception {
      // The next update or launch finishes them.
    }
  });

  Future<void> _finishUnfinished() async {
    for (final transaction in await _gateway.unfinished()) {
      final id = int.tryParse(transaction.id);
      if (id != null) await _gateway.finish(id);
    }
  }

  static FailureResult<T> _failure<T>() =>
      FailureResult<T>(const StoreFailure());

  /// Runs [body]; an exception or (when [timed]) no answer in [timeout] is a
  /// [StoreFailure].
  Future<Result<T>> _guard<T>(
    Future<Result<T>> Function() body, {
    bool timed = false,
  }) async {
    try {
      final call = body();
      return await (timed ? call.timeout(timeout) : call);
    } on Exception {
      return _failure();
    }
  }

  static Offer _offer(
    PlanKind plan,
    SK2Product product, {
    required bool trialEligible,
  }) => Offer(
    plan: plan,
    displayPrice: product.displayPrice,
    price: product.price,
    currencyCode: product.priceLocale.currencyCode,
    currencySymbol: product.priceLocale.currencySymbol,
    trialEligible: plan == PlanKind.annual && trialEligible,
  );

  static List<StoreTransaction> _ours(List<SK2Transaction> transactions) => [
    for (final transaction in transactions)
      if (PlanKind.ofProductId(transaction.productId) case final plan?)
        StoreTransaction(
          plan: plan,
          purchasedAt: _date(transaction.purchaseDate) ?? DateTime(0),
          expiresAt: _date(transaction.expirationDate),
        ),
  ];

  /// The plugin sends dates as milliseconds since the epoch, in a string.
  static DateTime? _date(String? millis) =>
      switch (int.tryParse(millis ?? '')) {
        final int value => DateTime.fromMillisecondsSinceEpoch(value),
        null => null,
      };
}

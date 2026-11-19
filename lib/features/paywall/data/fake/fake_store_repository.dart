import 'dart:async';

import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/features/paywall/domain/entities/access.dart';
import 'package:exhale/features/paywall/domain/entities/offer.dart';
import 'package:exhale/features/paywall/domain/entities/plan_kind.dart';
import 'package:exhale/features/paywall/domain/entities/purchase_outcome.dart';
import 'package:exhale/features/paywall/domain/entities/renewing_subscription.dart';
import 'package:exhale/features/paywall/domain/repositories/store_repository.dart';

/// A store held in memory, for tests and debug walks.
class FakeStoreRepository implements StoreRepository {
  FakeStoreRepository({
    this.access = const NeverPaid(),
    List<Offer>? offers,
    this.offline = false,
    this.renewing,
    DateTime Function()? now,
  }) : offers = offers ?? defaultOffers,
       _now = now ?? DateTime.now;

  /// Lifetime.
  factory FakeStoreRepository.entitled() => FakeStoreRepository(
    access: const Entitled(
      plan: PlanKind.lifetime,
      expiresAt: null,
      inTrial: false,
    ),
  );

  static const List<Offer> defaultOffers = [
    Offer(
      plan: PlanKind.annual,
      displayPrice: r'$34.99',
      price: 34.99,
      currencyCode: 'USD',
      currencySymbol: r'$',
      trialEligible: true,
    ),
    Offer(
      plan: PlanKind.monthly,
      displayPrice: r'$7.99',
      price: 7.99,
      currencyCode: 'USD',
      currencySymbol: r'$',
      trialEligible: false,
    ),
    Offer(
      plan: PlanKind.lifetime,
      displayPrice: r'$59.99',
      price: 59.99,
      currencyCode: 'USD',
      currencySymbol: r'$',
      trialEligible: false,
    ),
  ];

  final DateTime Function() _now;
  final StreamController<void> _changes = StreamController.broadcast();

  Access access;
  List<Offer> offers;

  /// Every call fails as if the App Store could not be reached.
  bool offline;

  /// What the next purchase sheet ends with.
  PurchaseOutcome nextOutcome = PurchaseOutcome.purchased;

  /// Returned once by the next purchase or restore.
  Failure? nextFailure;

  /// What a restore finds; null finds nothing.
  Access? restoreFinds;

  /// A subscription still renewing (beside Lifetime, say). While null, an
  /// Annual or Monthly [access] renews itself unless [autoRenew] is off.
  RenewingSubscription? renewing;

  /// Whether the current Annual or Monthly subscription renews.
  bool autoRenew = true;

  /// The renewal check fails.
  bool renewingFails = false;

  /// While set and not completed, a restore waits on it.
  Completer<void>? restoreGate;

  /// While set and not completed, Apple's sheets (manage, redeem, refund)
  /// stay open.
  Completer<void>? sheetGate;

  /// What the refund sheet ends with.
  RefundOutcome refundOutcome = RefundOutcome.requested;

  int purchaseCalls = 0;
  int restoreCalls = 0;
  int manageCalls = 0;
  int redeemCalls = 0;
  final List<PlanKind> refundRequests = [];

  void emitChange() => _changes.add(null);

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<Result<List<Offer>>> loadOffers() async =>
      offline ? _offline() : Success(offers);

  @override
  Future<Result<Access>> currentAccess() async =>
      offline ? _offline() : Success(access);

  @override
  Future<Result<PurchaseOutcome>> purchase(PlanKind plan) async {
    purchaseCalls++;
    if (_takeFailure() case final failure?) return FailureResult(failure);
    if (offline) return _offline();
    if (nextOutcome == PurchaseOutcome.purchased) access = _bought(plan);
    return Success(nextOutcome);
  }

  @override
  Future<Result<void>> restore() async {
    restoreCalls++;
    if (restoreGate case final gate?) await gate.future;
    if (_takeFailure() case final failure?) return FailureResult(failure);
    if (offline) return _offline();
    if (restoreFinds case final found?) access = found;
    return const Success(null);
  }

  @override
  Future<Result<void>> manageSubscriptions() async {
    manageCalls++;
    if (sheetGate case final gate?) await gate.future;
    return offline ? _offline() : const Success(null);
  }

  @override
  Future<Result<void>> presentCodeRedemption() async {
    redeemCalls++;
    if (sheetGate case final gate?) await gate.future;
    return offline ? _offline() : const Success(null);
  }

  @override
  Future<Result<RefundOutcome>> requestRefund(PlanKind plan) async {
    refundRequests.add(plan);
    if (sheetGate case final gate?) await gate.future;
    return offline ? _offline() : Success(refundOutcome);
  }

  @override
  Future<Result<RenewingSubscription?>> renewingSubscription() async {
    if (offline || renewingFails) return _offline();
    if (renewing case final renewing?) return Success(renewing);
    return Success(switch (access) {
      Entitled(:final plan, :final expiresAt?)
          when autoRenew && plan != PlanKind.lifetime =>
        RenewingSubscription(plan: plan, renewsAt: expiresAt),
      _ => null,
    });
  }

  Failure? _takeFailure() {
    final failure = nextFailure;
    nextFailure = null;
    return failure;
  }

  Entitled _bought(PlanKind plan) {
    final trial =
        plan == PlanKind.annual &&
        offers.any((o) => o.plan == PlanKind.annual && o.trialEligible);
    final days = switch (plan) {
      PlanKind.annual => trial ? 7 : 365,
      PlanKind.monthly => 30,
      PlanKind.lifetime => null,
    };
    return Entitled(
      plan: plan,
      expiresAt: days == null ? null : _now().add(Duration(days: days)),
      inTrial: trial,
    );
  }

  static FailureResult<T> _offline<T>() =>
      FailureResult<T>(const StoreFailure());
}

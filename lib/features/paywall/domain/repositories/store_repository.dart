import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/features/paywall/domain/entities/access.dart';
import 'package:exhale/features/paywall/domain/entities/offer.dart';
import 'package:exhale/features/paywall/domain/entities/plan_kind.dart';
import 'package:exhale/features/paywall/domain/entities/purchase_outcome.dart';
import 'package:exhale/features/paywall/domain/entities/renewing_subscription.dart';

/// The App Store, as the app needs it. Failures are `StoreFailure`.
abstract interface class StoreRepository {
  /// Annual, Monthly and Lifetime, in that order.
  Future<Result<List<Offer>>> loadOffers();

  Future<Result<Access>> currentAccess();

  Future<Result<PurchaseOutcome>> purchase(PlanKind plan);

  Future<Result<void>> restore();

  Future<Result<void>> manageSubscriptions();

  /// Apple's offer code sheet. A redemption arrives through [changes].
  Future<Result<void>> presentCodeRedemption();

  /// Apple's refund sheet for [plan]'s latest transaction.
  Future<Result<RefundOutcome>> requestRefund(PlanKind plan);

  /// An Annual or Monthly still set to auto-renew; null when none.
  Future<Result<RenewingSubscription?>> renewingSubscription();

  /// Emits when a transaction arrives or changes outside a purchase call
  /// (renewal, refund, Ask to Buy approval).
  Stream<void> get changes;
}

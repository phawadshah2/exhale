import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/features/paywall/domain/entities/access.dart';
import 'package:exhale/features/paywall/domain/entities/offer.dart';
import 'package:exhale/features/paywall/domain/entities/plan_kind.dart';
import 'package:exhale/features/paywall/domain/entities/purchase_outcome.dart';

/// The App Store, as the app needs it. Failures are `StoreFailure`.
abstract interface class StoreRepository {
  /// Annual, Monthly and Lifetime, in that order.
  Future<Result<List<Offer>>> loadOffers();

  Future<Result<Access>> currentAccess();

  Future<Result<PurchaseOutcome>> purchase(PlanKind plan);

  Future<Result<void>> restore();

  Future<Result<void>> manageSubscriptions();

  /// Emits when a transaction arrives or changes outside a purchase call
  /// (renewal, refund, Ask to Buy approval).
  Stream<void> get changes;
}

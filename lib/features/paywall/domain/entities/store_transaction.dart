import 'package:exhale/features/paywall/domain/entities/plan_kind.dart';
import 'package:meta/meta.dart';

/// One App Store transaction for one of our products. [expiresAt] is null for
/// Lifetime.
@immutable
class StoreTransaction {
  const StoreTransaction({
    required this.plan,
    required this.purchasedAt,
    this.expiresAt,
  });

  final PlanKind plan;
  final DateTime purchasedAt;
  final DateTime? expiresAt;

  @override
  bool operator ==(Object other) =>
      other is StoreTransaction &&
      other.plan == plan &&
      other.purchasedAt == purchasedAt &&
      other.expiresAt == expiresAt;

  @override
  int get hashCode => Object.hash(plan, purchasedAt, expiresAt);

  @override
  String toString() =>
      'StoreTransaction(${plan.name}, $purchasedAt, expires $expiresAt)';
}

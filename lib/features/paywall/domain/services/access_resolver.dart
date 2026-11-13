import 'package:exhale/features/paywall/domain/entities/access.dart';
import 'package:exhale/features/paywall/domain/entities/plan_kind.dart';
import 'package:exhale/features/paywall/domain/entities/store_transaction.dart';

/// The longest an Annual period can be and still be the 7-day free trial.
const _trialCeiling = Duration(days: 8);

const List<PlanKind> _rank = [
  PlanKind.lifetime,
  PlanKind.annual,
  PlanKind.monthly,
];

/// Works out access from the store's current entitlements and full history.
/// Never returns [AccessUnknown].
Access resolveAccess({
  required List<StoreTransaction> current,
  required List<StoreTransaction> history,
}) {
  if (current.isNotEmpty) {
    final best = current.reduce(
      (a, b) => _rank.indexOf(b.plan) < _rank.indexOf(a.plan) ? b : a,
    );
    final expiresAt = best.expiresAt;
    return Entitled(
      plan: best.plan,
      expiresAt: expiresAt,
      inTrial:
          best.plan == PlanKind.annual &&
          expiresAt != null &&
          expiresAt.difference(best.purchasedAt) <= _trialCeiling,
    );
  }
  if (history.isNotEmpty) {
    final newest = history.reduce(
      (a, b) => b.purchasedAt.isAfter(a.purchasedAt) ? b : a,
    );
    return Lapsed(plan: newest.plan, endedAt: newest.expiresAt);
  }
  return const NeverPaid();
}

import 'package:exhale/features/paywall/domain/entities/plan_kind.dart';
import 'package:meta/meta.dart';

/// What the user may do in the app, worked out from the App Store.
@immutable
sealed class Access {
  const Access();
}

/// A current subscription or Lifetime. [expiresAt] is null for Lifetime.
final class Entitled extends Access {
  const Entitled({
    required this.plan,
    required this.expiresAt,
    required this.inTrial,
  });

  final PlanKind plan;
  final DateTime? expiresAt;
  final bool inTrial;

  @override
  bool operator ==(Object other) =>
      other is Entitled &&
      other.plan == plan &&
      other.expiresAt == expiresAt &&
      other.inTrial == inTrial;

  @override
  int get hashCode => Object.hash(plan, expiresAt, inTrial);

  @override
  String toString() =>
      'Entitled(${plan.name}, until $expiresAt${inTrial ? ', trial' : ''})';
}

/// No transaction for any of our products.
final class NeverPaid extends Access {
  const NeverPaid();

  @override
  bool operator ==(Object other) => other is NeverPaid;

  @override
  int get hashCode => (NeverPaid).hashCode;

  @override
  String toString() => 'NeverPaid()';
}

/// Paid before, nothing current. [endedAt] is null when the store gives no
/// end date (a refunded Lifetime).
final class Lapsed extends Access {
  const Lapsed({required this.plan, required this.endedAt});

  final PlanKind plan;
  final DateTime? endedAt;

  @override
  bool operator ==(Object other) =>
      other is Lapsed && other.plan == plan && other.endedAt == endedAt;

  @override
  int get hashCode => Object.hash(plan, endedAt);

  @override
  String toString() => 'Lapsed(${plan.name}, ended $endedAt)';
}

/// The App Store did not answer.
final class AccessUnknown extends Access {
  const AccessUnknown();

  @override
  bool operator ==(Object other) => other is AccessUnknown;

  @override
  int get hashCode => (AccessUnknown).hashCode;

  @override
  String toString() => 'AccessUnknown()';
}

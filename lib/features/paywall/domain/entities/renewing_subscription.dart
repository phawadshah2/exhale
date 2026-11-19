import 'package:exhale/features/paywall/domain/entities/plan_kind.dart';
import 'package:meta/meta.dart';

/// An Annual or Monthly subscription still set to auto-renew.
@immutable
class RenewingSubscription {
  const RenewingSubscription({required this.plan, required this.renewsAt});

  final PlanKind plan;
  final DateTime renewsAt;

  @override
  bool operator ==(Object other) =>
      other is RenewingSubscription &&
      other.plan == plan &&
      other.renewsAt == renewsAt;

  @override
  int get hashCode => Object.hash(plan, renewsAt);

  @override
  String toString() => 'RenewingSubscription(${plan.name}, $renewsAt)';
}

/// How Apple's refund sheet ended, short of an error.
enum RefundOutcome { requested, cancelled }

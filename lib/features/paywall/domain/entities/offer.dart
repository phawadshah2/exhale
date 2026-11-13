import 'package:exhale/features/paywall/domain/entities/plan_kind.dart';
import 'package:meta/meta.dart';

/// A plan as the App Store sells it in the user's storefront.
@immutable
class Offer {
  const Offer({
    required this.plan,
    required this.displayPrice,
    required this.price,
    required this.currencyCode,
    required this.currencySymbol,
    required this.trialEligible,
  });

  final PlanKind plan;

  /// The localized price, shown as is.
  final String displayPrice;
  final double price;
  final String currencyCode;
  final String currencySymbol;

  /// True only for Annual when the user may still take the free week.
  final bool trialEligible;

  @override
  bool operator ==(Object other) =>
      other is Offer &&
      other.plan == plan &&
      other.displayPrice == displayPrice &&
      other.price == price &&
      other.currencyCode == currencyCode &&
      other.currencySymbol == currencySymbol &&
      other.trialEligible == trialEligible;

  @override
  int get hashCode => Object.hash(
    plan,
    displayPrice,
    price,
    currencyCode,
    currencySymbol,
    trialEligible,
  );

  @override
  String toString() =>
      'Offer(${plan.name}, $displayPrice${trialEligible ? ', trial' : ''})';
}

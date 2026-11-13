import 'dart:math' as math;

import 'package:exhale/features/paywall/domain/entities/offer.dart';
import 'package:exhale/features/paywall/domain/entities/plan_kind.dart';

/// Whole days of the habit's spend that cost as much as [offer], at least 1.
/// Null when there is no spend to compare, the user's currency is not the
/// storefront's, or it takes longer than the offer's period.
int? daysToCover({
  required double? unitPriceCents,
  required int startLimit,
  required String userCurrency,
  required Offer offer,
}) {
  if (unitPriceCents == null) return null;
  final dailySpend = startLimit * unitPriceCents / 100;
  if (dailySpend <= 0) return null;
  if (userCurrency != offer.currencySymbol &&
      userCurrency != offer.currencyCode) {
    return null;
  }
  final days = math.max(1, (offer.price / dailySpend).ceil());
  final period = offer.plan == PlanKind.monthly ? 30 : 365;
  return days > period ? null : days;
}

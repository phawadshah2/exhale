import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/paywall/data/fake/fake_store_repository.dart';
import 'package:exhale/features/paywall/domain/entities/offer.dart';
import 'package:exhale/features/paywall/domain/entities/plan_kind.dart';
import 'package:exhale/features/paywall/domain/services/spend_comparison.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Offer offer(PlanKind plan) =>
      FakeStoreRepository.defaultOffers.firstWhere((o) => o.plan == plan);

  int? days(
    PlanKind plan, {
    double? unitPriceCents = 75,
    int startLimit = 12,
    String currency = r'$',
  }) => daysToCover(
    unitPriceCents: unitPriceCents,
    startLimit: startLimit,
    userCurrency: currency,
    offer: offer(plan),
  );

  group('daysToCover', () {
    test('12 a day at 75 cents covers each plan in whole days', () {
      expect(days(PlanKind.annual), 4);
      expect(days(PlanKind.monthly), 1);
      expect(days(PlanKind.lifetime), 7);
    });

    test('matches the currency by symbol or by code', () {
      expect(days(PlanKind.annual, currency: 'USD'), 4);
      expect(days(PlanKind.annual, currency: 'AED'), isNull);
    });

    test('is null with no price or no spend', () {
      expect(days(PlanKind.annual, unitPriceCents: null), isNull);
      expect(days(PlanKind.annual, unitPriceCents: 0), isNull);
      expect(days(PlanKind.annual, unitPriceCents: -5), isNull);
    });

    test("is null past the offer's period", () {
      // 1 a day at 1 cent: 3499 days for Annual, 799 for Monthly.
      expect(days(PlanKind.annual, unitPriceCents: 1, startLimit: 1), isNull);
      expect(days(PlanKind.lifetime, unitPriceCents: 1, startLimit: 1), isNull);
      // 30 cents a day: 27 days for Monthly, 117 for Annual.
      expect(days(PlanKind.monthly, unitPriceCents: 30, startLimit: 1), 27);
      // 20 cents a day: 40 days for Monthly.
      expect(days(PlanKind.monthly, unitPriceCents: 20, startLimit: 1), isNull);
      expect(days(PlanKind.annual, unitPriceCents: 10, startLimit: 1), 350);
    });

    test('is never 0', () {
      expect(days(PlanKind.annual, unitPriceCents: 100000), 1);
    });
  });

  group('spendNoun', () {
    test("is the container's plural, else the units", () {
      expect(Habit.vaping.spendNoun, 'pods');
      expect(Habit.smoking.spendNoun, 'packs');
      expect(Habit.caffeine.spendNoun, Habit.caffeine.units);
      expect(Habit.custom(name: 'Gaming', unit: 'game').spendNoun, 'games');
    });
  });
}

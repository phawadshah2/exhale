import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/domain/entities/price_history.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final nov1 = LogicalDay(2026, 11, 1);
  final nov2 = LogicalDay(2026, 11, 2);
  final nov3 = LogicalDay(2026, 11, 3);
  final nov5 = LogicalDay(2026, 11, 5);

  PricePoint point(LogicalDay day, int? cents, {int units = 20}) =>
      PricePoint(fromDay: day, priceCents: cents, unitsPerContainer: units);

  final twoPrices = PriceHistory.forHabit(Habit.smoking, [
    point(nov1, 800),
    point(nov2, 900),
  ]);

  test('a day uses the latest point on or before it', () {
    expect(twoPrices.unitPriceCentsOn(nov1), 40);
    expect(twoPrices.unitPriceCentsOn(nov2), 45);
    expect(twoPrices.unitPriceCentsOn(nov3), 45);
  });

  test('a price is the first only with no point, or one on that day', () {
    PriceHistory of(List<PricePoint> points) =>
        PriceHistory.forHabit(Habit.smoking, points);

    expect(of(const []).isFirstPriceOn(nov2), isTrue);
    expect(of([point(nov2, 800)]).isFirstPriceOn(nov2), isTrue);
    expect(of([point(nov1, 800)]).isFirstPriceOn(nov2), isFalse);
    expect(
      of([point(nov1, 800), point(nov2, null)]).isFirstPriceOn(nov2),
      isFalse,
    );
  });

  test('days before the first point use the first point', () {
    expect(twoPrices.unitPriceCentsOn(nov1.addDays(-20)), 40);
  });

  test('a point with no price counts nothing until the next priced one', () {
    final history = PriceHistory.forHabit(Habit.smoking, [
      point(nov1, 800),
      point(nov3, null),
      point(nov5, 1000),
    ]);

    expect(history.unitPriceCentsOn(nov2), 40);
    expect(history.unitPriceCentsOn(nov3), isNull);
    expect(history.unitPriceCentsOn(nov3.addDays(1)), isNull);
    expect(history.unitPriceCentsOn(nov5), 50);
    expect(history.currentUnitPriceCents, 50);
  });

  test('a units change reprices from that day only', () {
    final history = PriceHistory.forHabit(Habit.smoking, [
      point(nov1, 800),
      point(nov2, 800, units: 10),
    ]);

    expect(history.unitPriceCentsOn(nov1), 40);
    expect(history.unitPriceCentsOn(nov2), 80);
  });

  test('a habit with no container is priced per unit', () {
    final history = PriceHistory.forHabit(Habit.caffeine, [point(nov1, 450)]);

    expect(history.unitPriceCentsOn(nov1), 450);
    expect(history.currentUnitPriceCents, 450);
  });

  test('a habit with no cost has no price on any day', () {
    final history = PriceHistory.forHabit(Habit.socialMedia, [
      point(nov1, 500),
    ]);

    expect(history.unitPriceCentsOn(nov1), isNull);
    expect(history.currentUnitPriceCents, isNull);
  });

  test('the current price is the latest point', () {
    expect(twoPrices.currentUnitPriceCents, 45);
    expect(
      PriceHistory.forHabit(Habit.smoking, [
        point(nov1, 800),
        point(nov2, null),
      ]).currentUnitPriceCents,
      isNull,
    );
  });

  test('no points: no price', () {
    const history = PriceHistory.forHabit(Habit.smoking, []);

    expect(history.unitPriceCentsOn(nov1), isNull);
    expect(history.currentUnitPriceCents, isNull);
  });
}

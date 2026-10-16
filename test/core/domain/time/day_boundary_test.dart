import 'package:exhale/core/domain/time/day_boundary.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DayBoundary', () {
    const fourAm = DayBoundary();
    const midnight = DayBoundary(resetHour: 0);

    test('defaults to a 4 AM reset', () {
      expect(fourAm.resetHour, 4);
    });

    test('moments before the reset hour belong to the previous day', () {
      expect(
        fourAm.dayOf(DateTime(2026, 10, 16, 3, 59)),
        LogicalDay(2026, 10, 15),
      );
      expect(fourAm.dayOf(DateTime(2026, 10, 16, 4)), LogicalDay(2026, 10, 16));
      expect(
        fourAm.dayOf(DateTime(2026, 10, 16, 23, 59)),
        LogicalDay(2026, 10, 16),
      );
    });

    test('a late night crosses month and year correctly', () {
      expect(fourAm.dayOf(DateTime(2027, 1, 1, 1)), LogicalDay(2026, 12, 31));
    });

    test('a midnight reset follows the calendar', () {
      expect(midnight.dayOf(DateTime(2026, 10, 16)), LogicalDay(2026, 10, 16));
      expect(
        midnight.dayOf(DateTime(2026, 10, 15, 23, 59)),
        LogicalDay(2026, 10, 15),
      );
    });

    test('UTC instants are judged in local time', () {
      final local = DateTime(2026, 10, 16, 2);

      expect(fourAm.dayOf(local.toUtc()), fourAm.dayOf(local));
    });

    test('startOf and endOf bound exactly one logical day', () {
      final day = LogicalDay(2026, 10, 16);

      expect(fourAm.startOf(day), DateTime(2026, 10, 16, 4));
      expect(fourAm.endOf(day), DateTime(2026, 10, 17, 4));
      expect(fourAm.dayOf(fourAm.startOf(day)), day);
      expect(
        fourAm.dayOf(fourAm.endOf(day).subtract(const Duration(seconds: 1))),
        day,
      );
      expect(fourAm.dayOf(fourAm.endOf(day)), day.addDays(1));
    });

    test('rejects hours outside 0-23', () {
      expect(() => DayBoundary(resetHour: 24), throwsA(isA<AssertionError>()));
      expect(() => DayBoundary(resetHour: -1), throwsA(isA<AssertionError>()));
    });

    test('equality is by reset hour', () {
      expect(const DayBoundary(resetHour: 5), const DayBoundary(resetHour: 5));
      expect(fourAm, isNot(midnight));
    });
  });
}

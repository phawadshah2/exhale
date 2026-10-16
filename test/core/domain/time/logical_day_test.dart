import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LogicalDay', () {
    test('equality ignores how the day was built', () {
      expect(LogicalDay(2026, 10, 16), LogicalDay(2026, 10, 16));
      expect(
        LogicalDay.fromDate(DateTime(2026, 10, 16, 23, 59)),
        LogicalDay(2026, 10, 16),
      );
      expect(
        LogicalDay(2026, 10, 16).hashCode,
        LogicalDay(2026, 10, 16).hashCode,
      );
      expect(LogicalDay(2026, 10, 16), isNot(LogicalDay(2026, 10, 17)));
    });

    test('toString is ISO yyyy-mm-dd', () {
      expect(LogicalDay(2026, 3, 7).toString(), '2026-03-07');
    });

    test('parse round-trips toString', () {
      expect(LogicalDay.parse('2026-03-07'), LogicalDay(2026, 3, 7));
      expect(LogicalDay.parse('2028-02-29'), LogicalDay(2028, 2, 29));
    });

    test('parse rejects malformed and impossible dates', () {
      expect(() => LogicalDay.parse('2026-3-7'), throwsFormatException);
      expect(() => LogicalDay.parse('07/03/2026'), throwsFormatException);
      expect(() => LogicalDay.parse('2026-02-30'), throwsFormatException);
    });

    test('addDays crosses month, year and leap-day boundaries', () {
      expect(LogicalDay(2026, 10, 31).addDays(1), LogicalDay(2026, 11, 1));
      expect(LogicalDay(2026, 12, 31).addDays(1), LogicalDay(2027, 1, 1));
      expect(LogicalDay(2028, 2, 28).addDays(1), LogicalDay(2028, 2, 29));
      expect(LogicalDay(2027, 2, 28).addDays(1), LogicalDay(2027, 3, 1));
      expect(LogicalDay(2026, 1, 1).addDays(-1), LogicalDay(2025, 12, 31));
    });

    test('daysSince counts whole days and can be negative', () {
      final start = LogicalDay(2026, 10, 15);

      expect(LogicalDay(2026, 10, 15).daysSince(start), 0);
      expect(LogicalDay(2026, 12, 17).daysSince(start), 63);
      expect(LogicalDay(2026, 10, 10).daysSince(start), -5);
      expect(LogicalDay(2027, 10, 15).daysSince(start), 365);
    });

    test('isBefore, isAfter and compareTo order by date', () {
      final a = LogicalDay(2026, 10, 15);
      final b = LogicalDay(2026, 10, 16);

      expect(a.isBefore(b), isTrue);
      expect(b.isAfter(a), isTrue);
      expect(a.isAfter(a), isFalse);
      expect([b, a]..sort(), [a, b]);
    });

    test('startOfWeek is the Monday of that week', () {
      // 2026-10-15 is a Thursday.
      expect(LogicalDay(2026, 10, 15).weekday, DateTime.thursday);
      expect(LogicalDay(2026, 10, 15).startOfWeek, LogicalDay(2026, 10, 12));
      expect(LogicalDay(2026, 10, 12).startOfWeek, LogicalDay(2026, 10, 12));
      expect(LogicalDay(2026, 10, 18).startOfWeek, LogicalDay(2026, 10, 12));
    });

    test('month helpers', () {
      expect(LogicalDay(2026, 10, 15).startOfMonth, LogicalDay(2026, 10, 1));
      expect(LogicalDay(2026, 2, 10).daysInMonth, 28);
      expect(LogicalDay(2028, 2, 10).daysInMonth, 29);
      expect(LogicalDay(2026, 12, 10).daysInMonth, 31);
    });

    test('toLocalDate is local midnight', () {
      expect(LogicalDay(2026, 10, 16).toLocalDate(), DateTime(2026, 10, 16));
    });
  });
}

import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/formatting/app_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final oct16 = LogicalDay(2026, 10, 16);

  test('dates', () {
    expect(AppFormat.monthDay(oct16), 'Oct 16');
    expect(AppFormat.fullDate(LogicalDay(2026, 12, 17)), '17 Dec 2026');
    expect(AppFormat.weekdayDate(LogicalDay(2026, 10, 18)), 'Sunday, Oct 18');
  });

  test('relative dates', () {
    expect(AppFormat.relativeDate(oct16, today: oct16), 'Today, Oct 16');
    expect(
      AppFormat.relativeDate(oct16.addDays(1), today: oct16),
      'Tomorrow, Oct 17',
    );
    expect(
      AppFormat.relativeDate(oct16.addDays(-1), today: oct16),
      'Yesterday, Oct 15',
    );
    expect(
      AppFormat.relativeDate(oct16.addDays(5), today: oct16),
      'Wednesday, Oct 21',
    );
  });

  test('12-hour time', () {
    expect(AppFormat.time(DateTime(2026, 10, 16, 15, 42)), '3:42 PM');
    expect(AppFormat.time(DateTime(2026, 10, 16, 0, 5)), '12:05 AM');
    expect(AppFormat.time(DateTime(2026, 10, 16, 12)), '12:00 PM');
    expect(AppFormat.time(DateTime(2026, 10, 16, 8, 15)), '8:15 AM');
  });

  test('money', () {
    expect(AppFormat.money(1450, symbol: r'$'), r'$14.50');
    expect(AppFormat.money(18270, symbol: r'$', wholeUnits: true), r'$183');
    expect(AppFormat.money(1450, symbol: 'AED '), 'AED 14.50');
  });

  test('money spaces a letter symbol once', () {
    expect(AppFormat.money(1450, symbol: 'AED'), 'AED 14.50');
    expect(AppFormat.money(15000, symbol: 'Rs', wholeUnits: true), 'Rs 150');
    expect(AppFormat.money(500, symbol: 'kr'), 'kr 5.00');
    expect(AppFormat.money(1450, symbol: '£'), '£14.50');
    expect(AppFormat.money(1450, symbol: r'A$'), r'A$14.50');
  });

  test('money groups thousands', () {
    expect(
      AppFormat.money(182500, symbol: 'AED', wholeUnits: true),
      'AED 1,825',
    );
    expect(AppFormat.money(264625, symbol: '£'), '£2,646.25');
    expect(
      AppFormat.money(123456789, symbol: r'$', wholeUnits: true),
      r'$1,234,568',
    );
    expect(AppFormat.money(99999, symbol: r'$'), r'$999.99');
    expect(AppFormat.money(0, symbol: r'$', wholeUnits: true), r'$0');
    expect(AppFormat.money(-123450, symbol: r'$'), r'-$1,234.50');
  });

  test('parseCents', () {
    expect(AppFormat.parseCents('14.50'), 1450);
    expect(AppFormat.parseCents(' 14,5 '), 1450);
    expect(AppFormat.parseCents('20'), 2000);
    expect(AppFormat.parseCents('0.1'), 10);
    expect(AppFormat.parseCents(''), isNull);
    expect(AppFormat.parseCents('abc'), isNull);
    expect(AppFormat.parseCents('-3'), isNull);
  });

  test('greeting by hour', () {
    expect(AppFormat.greeting(DateTime(2026, 10, 16, 9)), 'Good morning');
    expect(AppFormat.greeting(DateTime(2026, 10, 16, 15)), 'Good afternoon');
    expect(AppFormat.greeting(DateTime(2026, 10, 16, 21)), 'Good evening');
    expect(AppFormat.greeting(DateTime(2026, 10, 16, 2)), 'Good evening');
  });

  test('elapsed', () {
    expect(AppFormat.elapsed(const Duration(seconds: 30)), 'Just now');
    expect(AppFormat.elapsed(const Duration(minutes: 12)), '12m');
    expect(AppFormat.elapsed(const Duration(hours: 1, minutes: 42)), '1h 42m');
    expect(AppFormat.elapsed(const Duration(hours: 3)), '3h');
    expect(AppFormat.elapsed(const Duration(days: 2, hours: 3)), '2d 3h');
    expect(AppFormat.elapsed(const Duration(days: 4)), '4d');
  });

  test('weekday initial', () {
    expect(AppFormat.weekdayInitial(oct16), 'F');
  });
}

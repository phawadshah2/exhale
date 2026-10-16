import 'package:meta/meta.dart';

/// A calendar date with no time of day.
///
/// Arithmetic runs on UTC midnight so daylight-saving shifts never turn a
/// day difference into 23 or 25 hours.
@immutable
class LogicalDay implements Comparable<LogicalDay> {
  LogicalDay(int year, int month, int day)
    : _utc = DateTime.utc(year, month, day);

  factory LogicalDay.fromDate(DateTime date) =>
      LogicalDay(date.year, date.month, date.day);

  /// Parses the `yyyy-mm-dd` form produced by [toString].
  factory LogicalDay.parse(String value) {
    final match = _isoDate.firstMatch(value);
    if (match == null) {
      throw FormatException('Expected yyyy-mm-dd', value);
    }
    final day = LogicalDay(
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
    );
    if (day.toString() != value) {
      throw FormatException('Not a real calendar date', value);
    }
    return day;
  }

  static final _isoDate = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  final DateTime _utc;

  int get year => _utc.year;
  int get month => _utc.month;
  int get day => _utc.day;

  /// [DateTime.monday] (1) to [DateTime.sunday] (7).
  int get weekday => _utc.weekday;

  /// Monday of this day's week.
  LogicalDay get startOfWeek => addDays(1 - weekday);

  LogicalDay get startOfMonth => LogicalDay(year, month, 1);

  int get daysInMonth => DateTime.utc(year, month + 1, 0).day;

  LogicalDay addDays(int days) => LogicalDay(year, month, day + days);

  /// Whole days from [other] to this day; negative if this is earlier.
  int daysSince(LogicalDay other) => _utc.difference(other._utc).inDays;

  bool isBefore(LogicalDay other) => _utc.isBefore(other._utc);

  bool isAfter(LogicalDay other) => _utc.isAfter(other._utc);

  /// Local midnight of this date.
  DateTime toLocalDate() => DateTime(year, month, day);

  @override
  int compareTo(LogicalDay other) => _utc.compareTo(other._utc);

  @override
  bool operator ==(Object other) => other is LogicalDay && other._utc == _utc;

  @override
  int get hashCode => _utc.hashCode;

  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';
}

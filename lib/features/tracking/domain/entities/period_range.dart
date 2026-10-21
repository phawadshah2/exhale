import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:meta/meta.dart';

enum ChartPeriod {
  week,
  month;

  /// First day of the week (Monday) or month containing [day].
  LogicalDay startOf(LogicalDay day) => switch (this) {
    ChartPeriod.week => day.startOfWeek,
    ChartPeriod.month => day.startOfMonth,
  };

  /// [day] moved by [steps] weeks or months. A month step keeps the day of
  /// the month, clamped to the end of shorter months.
  LogicalDay shift(LogicalDay day, int steps) {
    switch (this) {
      case ChartPeriod.week:
        return day.addDays(7 * steps);
      case ChartPeriod.month:
        final first = LogicalDay(day.year, day.month + steps, 1);
        final dayOfMonth = day.day < first.daysInMonth
            ? day.day
            : first.daysInMonth;
        return LogicalDay(first.year, first.month, dayOfMonth);
    }
  }

  /// Whole periods from [earlier]'s period to [later]'s; 0 when they share
  /// one.
  int periodsBetween(LogicalDay earlier, LogicalDay later) => switch (this) {
    ChartPeriod.week => later.startOfWeek.daysSince(earlier.startOfWeek) ~/ 7,
    ChartPeriod.month =>
      (later.year - earlier.year) * 12 + later.month - earlier.month,
  };
}

/// An inclusive run of days shown in the history chart.
@immutable
class PeriodRange {
  const PeriodRange(this.from, this.to);

  /// Monday to Sunday around [day].
  factory PeriodRange.weekOf(LogicalDay day) {
    final monday = day.startOfWeek;
    return PeriodRange(monday, monday.addDays(6));
  }

  /// First to last day of [day]'s month.
  factory PeriodRange.monthOf(LogicalDay day) {
    final first = day.startOfMonth;
    return PeriodRange(first, first.addDays(day.daysInMonth - 1));
  }

  factory PeriodRange.of(ChartPeriod period, LogicalDay day) =>
      switch (period) {
        ChartPeriod.week => PeriodRange.weekOf(day),
        ChartPeriod.month => PeriodRange.monthOf(day),
      };

  final LogicalDay from;
  final LogicalDay to;

  int get length => to.daysSince(from) + 1;

  List<LogicalDay> get days => [
    for (var i = 0; i < length; i++) from.addDays(i),
  ];

  @override
  bool operator ==(Object other) =>
      other is PeriodRange && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);

  @override
  String toString() => 'PeriodRange($from..$to)';
}

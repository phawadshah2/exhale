import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:meta/meta.dart';

enum ChartPeriod { week, month }

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

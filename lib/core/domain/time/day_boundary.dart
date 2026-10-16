import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:meta/meta.dart';

/// Decides which [LogicalDay] a moment belongs to.
///
/// With a reset hour of 4, a cigarette at 01:30 on Tuesday still counts
/// toward Monday.
@immutable
class DayBoundary {
  const DayBoundary({this.resetHour = defaultResetHour})
    : assert(
        resetHour >= 0 && resetHour < 24,
        'resetHour must be between 0 and 23',
      );

  static const int defaultResetHour = 4;

  final int resetHour;

  LogicalDay dayOf(DateTime instant) {
    final local = instant.toLocal();
    final calendarDay = LogicalDay.fromDate(local);
    return local.hour < resetHour ? calendarDay.addDays(-1) : calendarDay;
  }

  /// First local moment of [day] (inclusive).
  DateTime startOf(LogicalDay day) =>
      DateTime(day.year, day.month, day.day, resetHour);

  /// First local moment after [day] (exclusive).
  DateTime endOf(LogicalDay day) => startOf(day.addDays(1));

  @override
  bool operator ==(Object other) =>
      other is DayBoundary && other.resetHour == resetHour;

  @override
  int get hashCode => resetHour.hashCode;
}

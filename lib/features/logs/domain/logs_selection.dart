import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/logs/presentation/logs_query.dart';
import 'package:exhale/features/tracking/domain/entities/period_range.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:meta/meta.dart';

/// What the Logs page shows: a week, the day selected in it and an optional
/// trigger filter. [selected] stays put when the logical day changes, so
/// [canGoLater] takes the current day.
@immutable
class LogsSelection {
  const LogsSelection({
    required this.period,
    required this.selected,
    this.trigger,
  });

  /// Opens the week holding the range's end, on that day. A range running
  /// past [today] opens on today.
  factory LogsSelection.fromQuery(LogsQuery q, {required LogicalDay today}) {
    final to = q.to;
    final end = to == null || to.isAfter(today) ? today : to;
    return LogsSelection(
      period: PeriodRange.weekOf(end),
      selected: end,
      trigger: q.trigger,
    );
  }

  final PeriodRange period;
  final LogicalDay selected;
  final Trigger? trigger;

  /// Never moves past the week holding [today].
  LogsSelection step(int by, {required LogicalDay today}) {
    final moved = ChartPeriod.week.shift(period.from, by);
    final week = PeriodRange.weekOf(moved.isAfter(today) ? today : moved);
    return LogsSelection(
      period: week,
      selected: week.to.isAfter(today) ? today : week.to,
      trigger: trigger,
    );
  }

  /// Shows the week holding [day], with [day] selected.
  LogsSelection select(LogicalDay day) => LogsSelection(
    period: PeriodRange.weekOf(day),
    selected: day,
    trigger: trigger,
  );

  /// The same trigger again clears the filter.
  LogsSelection toggleTrigger(Trigger trigger) => LogsSelection(
    period: period,
    selected: selected,
    trigger: trigger == this.trigger ? null : trigger,
  );

  bool canGoEarlier(LogicalDay earliest) => period.from.isAfter(earliest);

  bool canGoLater(LogicalDay today) => period.to.isBefore(today);
}

import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/logs/presentation/logs_query.dart';
import 'package:exhale/features/tracking/domain/entities/period_range.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:meta/meta.dart';

enum LogsMode {
  week(ChartPeriod.week),
  month(ChartPeriod.month);

  LogsMode(this.unit);

  final ChartPeriod unit;
}

/// What the Logs page shows: a period, the day selected in it and an optional
/// trigger filter. [selected] stays put when the logical day changes, so
/// [canGoLater] takes the current day.
@immutable
class LogsSelection {
  const LogsSelection({
    required this.mode,
    required this.period,
    required this.selected,
    this.trigger,
  });

  /// A range running past [today] opens on the period holding today.
  factory LogsSelection.fromQuery(LogsQuery q, {required LogicalDay today}) {
    final from = q.from;
    final to = q.to;
    final mode =
        from == null ||
            to == null ||
            from == to ||
            PeriodRange(from, to) == PeriodRange.weekOf(from)
        ? LogsMode.week
        : LogsMode.month;
    final end = to == null || to.isAfter(today) ? today : to;
    final period = PeriodRange.of(mode.unit, end);
    return LogsSelection(
      mode: mode,
      period: period,
      selected: from == to ? end : _lastAvailable(period, today),
      trigger: q.trigger,
    );
  }

  final LogsMode mode;
  final PeriodRange period;
  final LogicalDay selected;
  final Trigger? trigger;

  /// Never moves past the period holding [today].
  LogsSelection step(int by, {required LogicalDay today}) {
    final moved = mode.unit.shift(period.from, by);
    return _showing(mode, moved.isAfter(today) ? today : moved, today);
  }

  LogsSelection withMode(LogsMode mode) => LogsSelection(
    mode: mode,
    period: PeriodRange.of(mode.unit, selected),
    selected: selected,
    trigger: trigger,
  );

  LogsSelection pickMonth(
    LogicalDay anyDayInMonth, {
    required LogicalDay today,
  }) => _showing(LogsMode.month, anyDayInMonth, today);

  LogsSelection select(LogicalDay day) => LogsSelection(
    mode: mode,
    period: PeriodRange.of(mode.unit, day),
    selected: day,
    trigger: trigger,
  );

  /// The same trigger again clears the filter.
  LogsSelection toggleTrigger(Trigger trigger) => LogsSelection(
    mode: mode,
    period: period,
    selected: selected,
    trigger: trigger == this.trigger ? null : trigger,
  );

  bool canGoEarlier(LogicalDay earliest) => period.from.isAfter(earliest);

  bool canGoLater(LogicalDay today) => period.to.isBefore(today);

  LogsSelection _showing(LogsMode mode, LogicalDay day, LogicalDay today) {
    final period = PeriodRange.of(mode.unit, day);
    return LogsSelection(
      mode: mode,
      period: period,
      selected: _lastAvailable(period, today),
      trigger: trigger,
    );
  }

  static LogicalDay _lastAvailable(PeriodRange period, LogicalDay today) =>
      period.to.isAfter(today) ? today : period.to;
}

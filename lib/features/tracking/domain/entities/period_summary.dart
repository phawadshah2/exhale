import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/tracking/domain/entities/daily_progress.dart';
import 'package:exhale/features/tracking/domain/entities/limit_status.dart';
import 'package:exhale/features/tracking/domain/entities/period_range.dart';
import 'package:meta/meta.dart';

enum DaySlotKind {
  /// Before the first plan started: back-filled logs, with no limit.
  beforePlan,

  /// Today or earlier, inside the plan.
  tracked,

  /// After today: only the planned limit is known.
  future,
}

/// One day in the history chart.
@immutable
class DaySlot {
  const DaySlot({
    required this.day,
    required this.kind,
    required this.isToday,
    this.progress,
    this.beforePlanCount,
    this.limit,
  });

  final LogicalDay day;
  final DaySlotKind kind;
  final bool isToday;

  /// Set for [DaySlotKind.tracked].
  final DailyProgress? progress;

  /// Logs on a [DaySlotKind.beforePlan] day up to today.
  final int? beforePlanCount;

  /// Logs that day, whether tracked or back-filled before the plan.
  int? get count => progress?.count ?? beforePlanCount;

  /// Limit for tracked and future days; null before the plan.
  final int? limit;

  @override
  bool operator ==(Object other) =>
      other is DaySlot &&
      other.day == day &&
      other.kind == kind &&
      other.isToday == isToday &&
      other.progress == progress &&
      other.beforePlanCount == beforePlanCount &&
      other.limit == limit;

  @override
  int get hashCode =>
      Object.hash(day, kind, isToday, progress, beforePlanCount, limit);
}

@immutable
class PeriodSummary {
  PeriodSummary({required this.range, required List<DaySlot> slots})
    : slots = List.unmodifiable(slots);

  final PeriodRange range;
  final List<DaySlot> slots;

  Iterable<DailyProgress> get _tracked =>
      slots.map((s) => s.progress).whereType<DailyProgress>();

  /// Mean per tracked day (today included), or null with none tracked.
  double? get averagePerDay {
    final tracked = _tracked.toList();
    if (tracked.isEmpty) return null;
    final total = tracked.fold<int>(0, (sum, p) => sum + p.count);
    return total / tracked.length;
  }

  int get daysOver =>
      _tracked.where((p) => p.status == LimitStatus.over).length;

  int get daysWithin =>
      _tracked.where((p) => p.status != LimitStatus.over).length;

  /// Highest count or limit in the period, for scaling the chart.
  int get peak => slots.fold(0, (peak, slot) {
    final count = slot.count ?? 0;
    final limit = slot.limit ?? 0;
    final high = count > limit ? count : limit;
    return high > peak ? high : peak;
  });
}

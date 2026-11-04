import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/plan/domain/entities/plan_hold.dart';
import 'package:exhale/features/plan/domain/entities/plan_stage.dart';
import 'package:meta/meta.dart';

/// A taper from [startLimit] per day on [startDay] to zero on [quitDay].
///
/// The limit falls evenly: on day `d` of `D` it is
/// `ceil(startLimit × (D − d) / D)`, so drops are spread across the plan
/// (9/day over 63 days drops by one every 7 days).
///
/// Each of [holds] pauses the taper: the limit of the day before the hold
/// stays for its days, and every later day reads the taper that many days
/// earlier. [quitDay] includes the held days; [agreedQuitDay] is the date the
/// taper itself was set to.
@immutable
class ReductionPlan {
  ReductionPlan({
    required this.startDay,
    required this.startLimit,
    required LogicalDay quitDay,
    List<PlanHold> holds = const [],
  }) : agreedQuitDay = quitDay,
       holds = List.unmodifiable(
         <PlanHold>[...holds]..sort((a, b) => a.startDay.compareTo(b.startDay)),
       ) {
    if (startLimit < 1) {
      throw ArgumentError.value(startLimit, 'startLimit', 'must be >= 1');
    }
    if (!quitDay.isAfter(startDay)) {
      throw ArgumentError.value(
        quitDay,
        'quitDay',
        'must be after startDay ($startDay)',
      );
    }
  }

  static const int minSuggestedDays = 14;
  static const int maxSuggestedDays = 90;

  /// About one fewer per week, kept between [minSuggestedDays] and
  /// [maxSuggestedDays].
  static LogicalDay suggestedQuitDay(LogicalDay startDay, int startLimit) =>
      startDay.addDays(
        (startLimit * 7).clamp(minSuggestedDays, maxSuggestedDays),
      );

  final LogicalDay startDay;
  final int startLimit;

  /// The quit date the taper was set to, before any hold.
  final LogicalDay agreedQuitDay;

  /// Earliest hold first.
  final List<PlanHold> holds;

  /// The day the plan ends: [agreedQuitDay] plus every held day.
  LogicalDay get quitDay =>
      agreedQuitDay.addDays(holds.fold<int>(0, (sum, hold) => sum + hold.days));

  /// Days from [startDay] to [quitDay], held days included.
  int get totalDays => quitDay.daysSince(startDay);

  int get _agreedDays => agreedQuitDay.daysSince(startDay);

  /// Average days between drops of one unit, held days left out.
  double get daysPerDrop => _agreedDays / startLimit;

  /// Every day before [quitDay] whose limit differs from the day before.
  late final List<PlanStage> stages = List.unmodifiable(_buildStages());

  int get stageCount => stages.length;

  /// Units not used by [quitDay] if every limit is kept, compared
  /// with staying at [startLimit].
  late final int plannedReduction = [
    for (var d = 0; d < totalDays; d++) startLimit - _limitAt(d),
  ].fold(0, (sum, value) => sum + value);

  int limitOn(LogicalDay day) {
    if (day.isBefore(startDay)) return startLimit;
    return _limitAt(day.daysSince(startDay));
  }

  bool hasStartedOn(LogicalDay day) => !day.isBefore(startDay);

  bool isCompleteOn(LogicalDay day) => !day.isBefore(quitDay);

  /// The stage in force, or null before [startDay] and from [quitDay].
  PlanStage? stageOn(LogicalDay day) {
    if (!hasStartedOn(day) || isCompleteOn(day)) return null;
    return stages.lastWhere((stage) => !stage.startDay.isAfter(day));
  }

  /// Next day the limit goes down, or null from [quitDay].
  LogicalDay? nextDropOn(LogicalDay day) {
    if (isCompleteOn(day)) return null;
    if (!hasStartedOn(day)) {
      return stages.length > 1 ? stages[1].startDay : quitDay;
    }
    return stageOn(day)!.endDay.addDays(1);
  }

  int? daysUntilNextDrop(LogicalDay day) => nextDropOn(day)?.daysSince(day);

  /// Share of the plan's days already behind [day], from 0 to 1.
  double progressOn(LogicalDay day) =>
      (day.daysSince(startDay) / totalDays).clamp(0, 1).toDouble();

  int _limitAt(int real) {
    var shift = 0;
    for (final hold in holds) {
      final at = hold.startDay.daysSince(startDay);
      if (real < at) break;
      if (real < at + hold.days) return _taperAt(at - 1 - shift);
      shift += hold.days;
    }
    return _taperAt(real - shift);
  }

  int _taperAt(int dayIndex) {
    if (dayIndex <= 0) return startLimit;
    if (dayIndex >= _agreedDays) return 0;
    final remaining = _agreedDays - dayIndex;
    // Integer ceil(startLimit * remaining / agreed days).
    return (startLimit * remaining + _agreedDays - 1) ~/ _agreedDays;
  }

  List<PlanStage> _buildStages() {
    final stages = <PlanStage>[];
    var stageStart = 0;
    for (var d = 1; d <= totalDays; d++) {
      if (d == totalDays || _limitAt(d) != _limitAt(stageStart)) {
        stages.add(
          PlanStage(
            number: stages.length + 1,
            limit: _limitAt(stageStart),
            startDay: startDay.addDays(stageStart),
            lengthDays: d - stageStart,
          ),
        );
        stageStart = d;
      }
    }
    return stages;
  }

  @override
  bool operator ==(Object other) =>
      other is ReductionPlan &&
      other.startDay == startDay &&
      other.startLimit == startLimit &&
      other.agreedQuitDay == agreedQuitDay &&
      _sameHolds(other.holds);

  bool _sameHolds(List<PlanHold> other) {
    if (other.length != holds.length) return false;
    for (var i = 0; i < holds.length; i++) {
      if (other[i] != holds[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(startDay, startLimit, agreedQuitDay, Object.hashAll(holds));

  @override
  String toString() =>
      'ReductionPlan($startLimit/day from $startDay, quit $quitDay)';
}

import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';
import 'package:meta/meta.dart';

/// Every plan the user has run, oldest first.
///
/// Editing the plan never rewrites the past: a new plan takes over from its
/// start day, and earlier days keep the limit that applied at the time.
@immutable
class PlanHistory {
  PlanHistory(Iterable<ReductionPlan> plans)
    : plans = List.unmodifiable(
        <ReductionPlan>[...plans]
          ..sort((a, b) => a.startDay.compareTo(b.startDay)),
      ) {
    if (this.plans.isEmpty) {
      throw ArgumentError.value(plans, 'plans', 'must not be empty');
    }
    for (var i = 1; i < this.plans.length; i++) {
      if (this.plans[i].startDay == this.plans[i - 1].startDay) {
        throw ArgumentError.value(
          plans,
          'plans',
          'two plans start on ${this.plans[i].startDay}',
        );
      }
    }
  }

  final List<ReductionPlan> plans;

  ReductionPlan get current => plans.last;

  LogicalDay get firstDay => plans.first.startDay;

  /// The plan in force on [day]. Days before the first plan use the first.
  ReductionPlan planOn(LogicalDay day) => plans.lastWhere(
    (p) => !p.startDay.isAfter(day),
    orElse: () => plans.first,
  );

  int limitOn(LogicalDay day) => planOn(day).limitOn(day);

  /// Starts [plan] from its start day, dropping any plan that would have
  /// begun on or after it.
  PlanHistory replan(ReductionPlan plan) => PlanHistory([
    ...plans.where((p) => p.startDay.isBefore(plan.startDay)),
    plan,
  ]);
}

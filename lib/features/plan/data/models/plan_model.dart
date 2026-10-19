import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';

extension PlanRowMapper on PlanRow {
  ReductionPlan toEntity() => ReductionPlan(
    startDay: LogicalDay.parse(startDay),
    startLimit: startLimit,
    quitDay: LogicalDay.parse(quitDay),
  );
}

extension ReductionPlanMapper on ReductionPlan {
  PlansCompanion toCompanion() => PlansCompanion.insert(
    startDay: startDay.toString(),
    startLimit: startLimit,
    quitDay: quitDay.toString(),
  );
}

import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/plan/data/datasources/plan_local_data_source.dart';
import 'package:exhale/features/plan/domain/entities/plan_hold.dart';
import 'package:exhale/features/plan/domain/entities/reduction_plan.dart';

extension PlanRecordMapper on PlanRecord {
  ReductionPlan toEntity() => ReductionPlan(
    startDay: LogicalDay.parse(plan.startDay),
    startLimit: plan.startLimit,
    quitDay: LogicalDay.parse(plan.quitDay),
    holds: [
      for (final hold in holds)
        PlanHold(startDay: LogicalDay.parse(hold.startDay), days: hold.days),
    ],
  );
}

extension ReductionPlanMapper on ReductionPlan {
  PlansCompanion toCompanion(int habitId) => PlansCompanion.insert(
    habitId: habitId,
    startDay: startDay.toString(),
    startLimit: startLimit,
    quitDay: agreedQuitDay.toString(),
  );
}

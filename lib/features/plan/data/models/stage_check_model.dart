import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/plan/data/datasources/stage_check_local_data_source.dart';
import 'package:exhale/features/plan/domain/entities/stage_check.dart';

extension StageCheckRecordMapper on StageCheckRecord {
  StageCheck toEntity() => StageCheck(
    planStartDay: LogicalDay.parse(planStartDay),
    windowEndDay: LogicalDay.parse(check.windowEndDay),
    checkDay: LogicalDay.parse(check.checkDay),
    outcome: StageOutcome.values.byName(check.outcome),
    answeredAt: check.answeredAt,
  );
}

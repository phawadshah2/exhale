import 'package:drift/drift.dart';
import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/features/tracking/domain/entities/smoke_log.dart';
import 'package:exhale/features/tracking/domain/entities/smoke_trigger.dart';

extension SmokeLogRowMapper on SmokeLogRow {
  SmokeLog toEntity() => SmokeLog(
    id: id,
    loggedAt: loggedAt,
    trigger: trigger == null ? null : SmokeTrigger.values.asNameMap()[trigger],
    note: note,
  );
}

SmokeLogsCompanion smokeLogCompanion({
  required DateTime loggedAt,
  required SmokeTrigger? trigger,
  required String? note,
}) => SmokeLogsCompanion(
  loggedAt: Value(loggedAt),
  trigger: Value(trigger?.name),
  note: Value(note),
);

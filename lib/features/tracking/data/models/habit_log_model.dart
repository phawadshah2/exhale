import 'package:drift/drift.dart' hide Trigger;
import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/features/tracking/domain/entities/habit_log.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';

extension HabitLogRowMapper on HabitLogRow {
  HabitLog toEntity() => HabitLog(
    id: id,
    habitId: habitId,
    loggedAt: loggedAt,
    trigger: trigger == null ? null : Trigger.values.asNameMap()[trigger],
    note: note,
  );
}

HabitLogsCompanion habitLogCompanion({
  required int habitId,
  required DateTime loggedAt,
  required Trigger? trigger,
  required String? note,
}) => HabitLogsCompanion(
  habitId: Value(habitId),
  loggedAt: Value(loggedAt),
  trigger: Value(trigger?.name),
  note: Value(note),
);

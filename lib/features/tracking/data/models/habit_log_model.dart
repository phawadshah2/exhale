import 'package:drift/drift.dart' hide Trigger;
import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/tracking/domain/entities/habit_log.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';

extension HabitLogRowMapper on HabitLogRow {
  HabitLog toEntity() => HabitLog(
    id: id,
    loggedAt: loggedAt,
    habitKind: HabitKind.values.asNameMap()[habitKind] ?? HabitKind.smoking,
    trigger: trigger == null ? null : Trigger.values.asNameMap()[trigger],
    note: note,
  );
}

HabitLogsCompanion habitLogCompanion({
  required DateTime loggedAt,
  required HabitKind habitKind,
  required Trigger? trigger,
  required String? note,
}) => HabitLogsCompanion(
  loggedAt: Value(loggedAt),
  habitKind: Value(habitKind.name),
  trigger: Value(trigger?.name),
  note: Value(note),
);

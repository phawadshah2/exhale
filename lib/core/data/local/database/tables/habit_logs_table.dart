import 'package:drift/drift.dart';
import 'package:exhale/core/data/local/database/tables/habits_table.dart';

@DataClassName('HabitLogRow')
@TableIndex(name: 'idx_habit_logs_logged_at', columns: {#loggedAt})
@TableIndex(
  name: 'idx_habit_logs_habit_id_logged_at',
  columns: {#habitId, #loggedAt},
)
class HabitLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId =>
      integer().named('habit_id').references(Habits, #id)();
  DateTimeColumn get loggedAt => dateTime().named('logged_at')();

  /// Trigger.name, or null when skipped.
  TextColumn get trigger => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();
}

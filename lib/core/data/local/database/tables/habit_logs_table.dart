import 'package:drift/drift.dart';

@DataClassName('HabitLogRow')
@TableIndex(name: 'idx_habit_logs_logged_at', columns: {#loggedAt})
class HabitLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get loggedAt => dateTime().named('logged_at')();

  /// HabitKind.name of the habit when it was logged; rows from before v7
  /// were smoking.
  TextColumn get habitKind =>
      text().named('habit_kind').withDefault(const Constant('smoking'))();

  /// Trigger.name, or null when skipped.
  TextColumn get trigger => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();
}

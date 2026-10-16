import 'package:drift/drift.dart';

@DataClassName('SmokeLogRow')
@TableIndex(name: 'idx_smoke_logs_logged_at', columns: {#loggedAt})
class SmokeLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get loggedAt => dateTime().named('logged_at')();

  /// SmokeTrigger.name, or null when skipped.
  TextColumn get trigger => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();
}

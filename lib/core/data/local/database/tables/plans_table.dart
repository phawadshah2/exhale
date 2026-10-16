import 'package:drift/drift.dart';

@DataClassName('PlanRow')
class Plans extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// LogicalDay in yyyy-mm-dd form.
  TextColumn get startDay => text().named('start_day').unique()();
  IntColumn get startLimit => integer().named('start_limit')();
  IntColumn get stepDays => integer().named('step_days')();
  IntColumn get targetLimit => integer().named('target_limit')();
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();
}

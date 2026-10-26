import 'package:drift/drift.dart';
import 'package:exhale/core/data/local/database/tables/habits_table.dart';

@DataClassName('PlanRow')
class Plans extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId =>
      integer().named('habit_id').references(Habits, #id)();

  /// LogicalDay in yyyy-mm-dd form.
  TextColumn get startDay => text().named('start_day')();
  IntColumn get startLimit => integer().named('start_limit')();

  /// LogicalDay in yyyy-mm-dd form; the limit is 0 from this day.
  TextColumn get quitDay => text().named('quit_day')();
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {habitId, startDay},
  ];
}

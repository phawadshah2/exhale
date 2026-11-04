import 'package:drift/drift.dart';
import 'package:exhale/core/data/local/database/tables/plans_table.dart';

@DataClassName('StageCheckRow')
class StageChecks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get planId => integer().named('plan_id').references(Plans, #id)();

  /// LogicalDay in yyyy-mm-dd form: the last day of the window checked.
  TextColumn get windowEndDay => text().named('window_end_day')();

  /// LogicalDay in yyyy-mm-dd form: the day the check ran.
  TextColumn get checkDay => text().named('check_day')();

  /// passed, skipped, hold, review or reassess.
  TextColumn get outcome => text()();

  /// Null while a hold, review or reassess card still waits.
  DateTimeColumn get answeredAt => dateTime().named('answered_at').nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {planId, windowEndDay},
  ];
}

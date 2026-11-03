import 'package:drift/drift.dart';
import 'package:exhale/core/data/local/database/tables/plans_table.dart';

@DataClassName('PlanHoldRow')
class PlanHolds extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get planId => integer().named('plan_id').references(Plans, #id)();

  /// LogicalDay in yyyy-mm-dd form; the limit stays put from this day.
  TextColumn get startDay => text().named('start_day')();
  IntColumn get days => integer().withDefault(const Constant(7))();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {planId, startDay},
  ];
}

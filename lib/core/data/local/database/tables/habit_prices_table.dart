import 'package:drift/drift.dart';
import 'package:exhale/core/data/local/database/tables/habits_table.dart';

@DataClassName('HabitPriceRow')
class HabitPrices extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId =>
      integer().named('habit_id').references(Habits, #id)();

  /// LogicalDay in yyyy-mm-dd form; the price counts from this day.
  TextColumn get fromDay => text().named('from_day')();

  /// Per container when the habit has one, else per unit. Null counts nothing
  /// from this day until the next priced point.
  IntColumn get priceCents => integer().named('price_cents').nullable()();
  IntColumn get unitsPerContainer => integer().named('units_per_container')();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {habitId, fromDay},
  ];
}

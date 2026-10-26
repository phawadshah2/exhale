import 'package:drift/drift.dart';
import 'package:exhale/core/data/local/database/app_database.dart';

class HabitLocalDataSource {
  const HabitLocalDataSource(this._database);
  final AppDatabase _database;

  SimpleSelectStatement<$HabitsTable, HabitRow> _active() =>
      _database.select(_database.habits)
        ..where((habit) => habit.archivedAt.isNull())
        ..orderBy([
          (habit) => OrderingTerm.asc(habit.createdAt),
          (habit) => OrderingTerm.asc(habit.id),
        ]);

  Stream<List<HabitRow>> watchActive() => _active().watch();

  Future<List<HabitRow>> getActive() => _active().get();

  Future<HabitRow> insertHabit(HabitsCompanion habit) =>
      _database.into(_database.habits).insertReturning(habit);

  Future<int> updateHabit(int id, HabitsCompanion habit) => (_database.update(
    _database.habits,
  )..where((row) => row.id.equals(id))).write(habit);
}

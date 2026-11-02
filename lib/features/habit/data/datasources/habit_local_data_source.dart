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

  SimpleSelectStatement<$HabitPricesTable, HabitPriceRow> _prices(
    int habitId,
  ) => _database.select(_database.habitPrices)
    ..where((price) => price.habitId.equals(habitId))
    ..orderBy([(price) => OrderingTerm.asc(price.fromDay)]);

  Stream<List<HabitPriceRow>> watchPrices(int habitId) =>
      _prices(habitId).watch();

  /// Updates the habit and its price points together; returns the habit rows
  /// updated. A point with no price is only ever written after a priced one.
  Future<int> setPrice(
    int habitId, {
    required String fromDay,
    required int? priceCents,
    required int unitsPerContainer,
  }) => _database.transaction(() async {
    final updated = await updateHabit(
      habitId,
      HabitsCompanion(
        priceCents: Value(priceCents),
        unitsPerContainer: Value(unitsPerContainer),
      ),
    );
    if (updated == 0) return 0;

    final points = await _prices(habitId).get();
    final latest = points.lastOrNull;
    final unchanged = priceCents == null
        ? latest?.priceCents == null
        : latest?.priceCents == priceCents &&
              latest?.unitsPerContainer == unitsPerContainer;
    if (unchanged) return updated;

    if (priceCents == null &&
        points.length == 1 &&
        latest!.fromDay == fromDay) {
      await (_database.delete(
        _database.habitPrices,
      )..where((price) => price.id.equals(latest.id))).go();
      return updated;
    }

    final point = HabitPricesCompanion.insert(
      habitId: habitId,
      fromDay: fromDay,
      priceCents: Value(priceCents),
      unitsPerContainer: unitsPerContainer,
    );
    await _database
        .into(_database.habitPrices)
        .insert(
          point,
          onConflict: DoUpdate(
            (_) => point,
            target: [
              _database.habitPrices.habitId,
              _database.habitPrices.fromDay,
            ],
          ),
        );
    return updated;
  });
}

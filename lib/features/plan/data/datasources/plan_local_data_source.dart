import 'package:drift/drift.dart';
import 'package:exhale/core/data/local/database/app_database.dart';

class PlanLocalDataSource {
  const PlanLocalDataSource(this._database);
  final AppDatabase _database;

  SimpleSelectStatement<$PlansTable, PlanRow> _ordered(int habitId) =>
      _database.select(_database.plans)
        ..where((plan) => plan.habitId.equals(habitId))
        ..orderBy([(plan) => OrderingTerm.asc(plan.startDay)]);

  Stream<List<PlanRow>> watchPlans(int habitId) => _ordered(habitId).watch();

  Future<List<PlanRow>> getPlans(int habitId) => _ordered(habitId).get();

  /// Deletes the habit's plans starting on or after the new plan, then
  /// inserts it.
  Future<void> replaceFrom(PlansCompanion plan) {
    final habitId = plan.habitId.value;
    final startDay = plan.startDay.value;
    return _database.transaction(() async {
      await (_database.delete(_database.plans)..where(
            (row) =>
                row.habitId.equals(habitId) &
                row.startDay.isBiggerOrEqualValue(startDay),
          ))
          .go();
      await _database.into(_database.plans).insert(plan);
    });
  }
}

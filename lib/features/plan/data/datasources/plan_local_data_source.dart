import 'package:drift/drift.dart';
import 'package:exhale/core/data/local/database/app_database.dart';

class PlanLocalDataSource {
  const PlanLocalDataSource(this._database);
  final AppDatabase _database;

  SimpleSelectStatement<$PlansTable, PlanRow> _ordered() =>
      _database.select(_database.plans)
        ..orderBy([(plan) => OrderingTerm.asc(plan.startDay)]);

  Stream<List<PlanRow>> watchPlans() => _ordered().watch();

  Future<List<PlanRow>> getPlans() => _ordered().get();

  /// Deletes plans starting on or after the new plan, then inserts it.
  Future<void> replaceFrom(PlansCompanion plan) {
    final startDay = plan.startDay.value;
    return _database.transaction(() async {
      await (_database.delete(
        _database.plans,
      )..where((row) => row.startDay.isBiggerOrEqualValue(startDay))).go();
      await _database.into(_database.plans).insert(plan);
    });
  }
}

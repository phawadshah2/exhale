import 'package:drift/drift.dart';
import 'package:exhale/core/data/local/database/app_database.dart';

/// A plan row with its holds, earliest first.
typedef PlanRecord = ({PlanRow plan, List<PlanHoldRow> holds});

class PlanLocalDataSource {
  const PlanLocalDataSource(this._database);
  final AppDatabase _database;

  /// Every plan of the habit joined to its holds, so a stream sees both
  /// tables.
  JoinedSelectStatement<HasResultSet, dynamic> _ordered(int habitId) {
    final plans = _database.plans;
    final holds = _database.planHolds;
    return _database.select(plans).join([
        leftOuterJoin(holds, holds.planId.equalsExp(plans.id)),
      ])
      ..where(plans.habitId.equals(habitId))
      ..orderBy([
        OrderingTerm.asc(plans.startDay),
        OrderingTerm.asc(holds.startDay),
      ]);
  }

  List<PlanRecord> _grouped(List<TypedResult> rows) {
    final byPlan = <int, ({PlanRow plan, List<PlanHoldRow> holds})>{};
    for (final row in rows) {
      final plan = row.readTable(_database.plans);
      final hold = row.readTableOrNull(_database.planHolds);
      final record = byPlan.putIfAbsent(
        plan.id,
        () => (plan: plan, holds: <PlanHoldRow>[]),
      );
      if (hold != null) record.holds.add(hold);
    }
    return byPlan.values.toList();
  }

  Stream<List<PlanRecord>> watchPlans(int habitId) =>
      _ordered(habitId).watch().map(_grouped);

  Future<List<PlanRecord>> getPlans(int habitId) async =>
      _grouped(await _ordered(habitId).get());

  /// Deletes the habit's plans starting on or after the new plan, with their
  /// holds and checks, then inserts it.
  Future<void> replaceFrom(PlansCompanion plan) {
    final habitId = plan.habitId.value;
    final startDay = plan.startDay.value;
    const dropped =
        'plan_id IN (SELECT id FROM plans '
        'WHERE habit_id = ? AND start_day >= ?)';
    final variables = [
      Variable.withInt(habitId),
      Variable.withString(startDay),
    ];
    return _database.transaction(() async {
      await _database.customUpdate(
        'DELETE FROM plan_holds WHERE $dropped',
        variables: variables,
        updates: {_database.planHolds},
      );
      await _database.customUpdate(
        'DELETE FROM stage_checks WHERE $dropped',
        variables: variables,
        updates: {_database.stageChecks},
      );
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

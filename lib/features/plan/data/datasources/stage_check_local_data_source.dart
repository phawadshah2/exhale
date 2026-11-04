import 'package:drift/drift.dart';
import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/plan/domain/entities/plan_hold.dart';
import 'package:exhale/features/plan/domain/entities/stage_check.dart';

/// A write that found no plan, hold or check to change. It rolls the whole
/// transaction back.
class MissingRowException implements Exception {
  const MissingRowException(this.what);
  final String what;

  @override
  String toString() => 'MissingRowException($what)';
}

/// A check row with the start day of its plan.
typedef StageCheckRecord = ({StageCheckRow check, String planStartDay});

class StageCheckLocalDataSource {
  const StageCheckLocalDataSource(this._database);
  final AppDatabase _database;

  JoinedSelectStatement<HasResultSet, dynamic> _newestFirst(int habitId) {
    final plans = _database.plans;
    final checks = _database.stageChecks;
    return _database.select(checks).join([
        innerJoin(plans, plans.id.equalsExp(checks.planId)),
      ])
      ..where(plans.habitId.equals(habitId))
      ..orderBy([
        OrderingTerm.desc(checks.checkDay),
        OrderingTerm.desc(checks.windowEndDay),
        OrderingTerm.desc(checks.id),
      ]);
  }

  List<StageCheckRecord> _records(List<TypedResult> rows) => [
    for (final row in rows)
      (
        check: row.readTable(_database.stageChecks),
        planStartDay: row.readTable(_database.plans).startDay,
      ),
  ];

  Stream<List<StageCheckRecord>> watchChecks(int habitId) =>
      _newestFirst(habitId).watch().map(_records);

  Future<List<StageCheckRecord>> getChecks(int habitId) async =>
      _records(await _newestFirst(habitId).get());

  Future<int> _planId(int habitId, LogicalDay planStartDay) async {
    final plan =
        await (_database.select(_database.plans)..where(
              (row) =>
                  row.habitId.equals(habitId) &
                  row.startDay.equals(planStartDay.toString()),
            ))
            .getSingleOrNull();
    if (plan == null) throw MissingRowException('plan from $planStartDay');
    return plan.id;
  }

  Future<void> _answer(int planId, LogicalDay windowEndDay, DateTime at) async {
    final changed =
        await (_database.update(_database.stageChecks)..where(
              (row) =>
                  row.planId.equals(planId) &
                  row.windowEndDay.equals(windowEndDay.toString()),
            ))
            .write(StageChecksCompanion(answeredAt: Value(at)));
    if (changed == 0) {
      throw MissingRowException('check for the window ending $windowEndDay');
    }
  }

  /// The check and its hold in one transaction. A window already recorded
  /// writes nothing.
  Future<void> record(
    int habitId,
    StageCheck check, {
    PlanHold? hold,
    LogicalDay? closesHoldWindow,
  }) => _database.transaction(() async {
    final planId = await _planId(habitId, check.planStartDay);
    final existing =
        await (_database.select(_database.stageChecks)..where(
              (row) =>
                  row.planId.equals(planId) &
                  row.windowEndDay.equals(check.windowEndDay.toString()),
            ))
            .getSingleOrNull();
    if (existing != null) return;

    await _database
        .into(_database.stageChecks)
        .insert(
          StageChecksCompanion.insert(
            planId: planId,
            windowEndDay: check.windowEndDay.toString(),
            checkDay: check.checkDay.toString(),
            outcome: check.outcome.name,
            answeredAt: Value(check.answeredAt),
          ),
        );
    if (hold != null) {
      await _database
          .into(_database.planHolds)
          .insert(
            PlanHoldsCompanion.insert(
              planId: planId,
              startDay: hold.startDay.toString(),
              days: Value(hold.days),
            ),
          );
    }
    if (closesHoldWindow != null) {
      // Closed on the day of the check that replaced it.
      final day = check.checkDay;
      await (_database.update(_database.stageChecks)..where(
            (row) =>
                row.planId.equals(planId) &
                row.windowEndDay.equals(closesHoldWindow.toString()) &
                row.outcome.equals(StageOutcome.hold.name) &
                row.answeredAt.isNull(),
          ))
          .write(
            StageChecksCompanion(
              answeredAt: Value(DateTime(day.year, day.month, day.day)),
            ),
          );
    }
  });

  Future<void> answer(
    int habitId,
    LogicalDay planStartDay,
    LogicalDay windowEndDay,
    DateTime at,
  ) async {
    final planId = await _planId(habitId, planStartDay);
    await _answer(planId, windowEndDay, at);
  }

  Future<void> keepOriginalDate(
    int habitId,
    LogicalDay planStartDay,
    LogicalDay windowEndDay,
    LogicalDay holdStart,
    DateTime at,
  ) => _database.transaction(() async {
    final planId = await _planId(habitId, planStartDay);
    final deleted =
        await (_database.delete(_database.planHolds)..where(
              (row) =>
                  row.planId.equals(planId) &
                  row.startDay.equals(holdStart.toString()),
            ))
            .go();
    if (deleted == 0) throw MissingRowException('hold from $holdStart');
    await _answer(planId, windowEndDay, at);
  });
}

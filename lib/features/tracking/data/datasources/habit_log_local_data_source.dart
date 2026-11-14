import 'package:drift/drift.dart';
import 'package:exhale/core/data/local/database/app_database.dart';

class HabitLogLocalDataSource {
  const HabitLogLocalDataSource(this._database);
  final AppDatabase _database;

  Future<HabitLogRow> insertLog(HabitLogsCompanion log) =>
      _database.into(_database.habitLogs).insertReturning(log);

  Future<int> updateLog(int id, HabitLogsCompanion log) => (_database.update(
    _database.habitLogs,
  )..where((row) => row.id.equals(id))).write(log);

  Future<int> deleteLog(int id) => (_database.delete(
    _database.habitLogs,
  )..where((row) => row.id.equals(id))).go();

  /// [habitId]'s logs, or every active habit's when null.
  Expression<bool> _ofHabit($HabitLogsTable row, int? habitId) =>
      habitId != null
      ? row.habitId.equals(habitId)
      : row.habitId.isInQuery(
          _database.selectOnly(_database.habits)
            ..addColumns([_database.habits.id])
            ..where(_database.habits.archivedAt.isNull()),
        );

  SimpleSelectStatement<$HabitLogsTable, HabitLogRow> _inRange(
    DateTime from,
    DateTime to,
    int? habitId,
  ) => _database.select(_database.habitLogs)
    ..where(
      (row) =>
          _ofHabit(row, habitId) &
          row.loggedAt.isBiggerOrEqualValue(from) &
          row.loggedAt.isSmallerThanValue(to),
    )
    ..orderBy([
      (row) => OrderingTerm.asc(row.loggedAt),
      (row) => OrderingTerm.asc(row.id),
    ]);

  Stream<List<HabitLogRow>> watchLogs({
    required DateTime from,
    required DateTime to,
    int? habitId,
  }) => _inRange(from, to, habitId).watch();

  Future<List<HabitLogRow>> getLogs({
    required DateTime from,
    required DateTime to,
    int? habitId,
  }) => _inRange(from, to, habitId).get();

  SimpleSelectStatement<$HabitLogsTable, HabitLogRow> _newest(
    int? habitId,
    int limit,
  ) => _database.select(_database.habitLogs)
    ..where((row) => _ofHabit(row, habitId))
    ..orderBy([
      (row) => OrderingTerm.desc(row.loggedAt),
      (row) => OrderingTerm.desc(row.id),
    ])
    ..limit(limit);

  Stream<HabitLogRow?> watchLatest({int? habitId}) =>
      _newest(habitId, 1).watchSingleOrNull();

  Future<HabitLogRow?> getLatest({int? habitId}) =>
      _newest(habitId, 1).getSingleOrNull();

  Stream<List<HabitLogRow>> watchRecent({required int limit}) =>
      _newest(null, limit).watch();
}

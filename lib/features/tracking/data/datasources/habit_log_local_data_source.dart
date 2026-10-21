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

  Stream<List<HabitLogRow>> watchLogs({
    required String habitKind,
    required DateTime from,
    required DateTime to,
  }) {
    final query = _database.select(_database.habitLogs)
      ..where(
        (row) =>
            row.habitKind.equals(habitKind) &
            row.loggedAt.isBiggerOrEqualValue(from) &
            row.loggedAt.isSmallerThanValue(to),
      )
      ..orderBy([
        (row) => OrderingTerm.asc(row.loggedAt),
        (row) => OrderingTerm.asc(row.id),
      ]);
    return query.watch();
  }

  Stream<HabitLogRow?> watchLatest({required String habitKind}) {
    final query = _database.select(_database.habitLogs)
      ..where((row) => row.habitKind.equals(habitKind))
      ..orderBy([
        (row) => OrderingTerm.desc(row.loggedAt),
        (row) => OrderingTerm.desc(row.id),
      ])
      ..limit(1);
    return query.watchSingleOrNull();
  }
}

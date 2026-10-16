import 'package:drift/drift.dart';
import 'package:exhale/core/data/local/database/app_database.dart';

class SmokeLogLocalDataSource {
  const SmokeLogLocalDataSource(this._database);
  final AppDatabase _database;

  Future<SmokeLogRow> insertLog(SmokeLogsCompanion log) =>
      _database.into(_database.smokeLogs).insertReturning(log);

  Future<int> updateLog(int id, SmokeLogsCompanion log) => (_database.update(
    _database.smokeLogs,
  )..where((row) => row.id.equals(id))).write(log);

  Future<int> deleteLog(int id) => (_database.delete(
    _database.smokeLogs,
  )..where((row) => row.id.equals(id))).go();

  Stream<List<SmokeLogRow>> watchLogs({
    required DateTime from,
    required DateTime to,
  }) {
    final query = _database.select(_database.smokeLogs)
      ..where(
        (row) =>
            row.loggedAt.isBiggerOrEqualValue(from) &
            row.loggedAt.isSmallerThanValue(to),
      )
      ..orderBy([
        (row) => OrderingTerm.asc(row.loggedAt),
        (row) => OrderingTerm.asc(row.id),
      ]);
    return query.watch();
  }

  Stream<SmokeLogRow?> watchLatest() {
    final query = _database.select(_database.smokeLogs)
      ..orderBy([
        (row) => OrderingTerm.desc(row.loggedAt),
        (row) => OrderingTerm.desc(row.id),
      ])
      ..limit(1);
    return query.watchSingleOrNull();
  }
}

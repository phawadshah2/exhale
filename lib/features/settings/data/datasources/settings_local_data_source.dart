import 'package:exhale/core/data/local/database/app_database.dart';

class SettingsLocalDataSource {
  const SettingsLocalDataSource(this._database);
  final AppDatabase _database;

  static const _rowId = 1;

  Stream<SettingsRow?> watchSettings() => (_database.select(
    _database.settings,
  )..where((row) => row.id.equals(_rowId))).watchSingleOrNull();

  Future<SettingsRow?> getSettings() => (_database.select(
    _database.settings,
  )..where((row) => row.id.equals(_rowId))).getSingleOrNull();

  Future<void> saveSettings(SettingsCompanion settings) =>
      _database.into(_database.settings).insertOnConflictUpdate(settings);
}

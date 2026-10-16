import 'package:exhale/core/data/storage_guard.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:exhale/features/settings/data/models/settings_model.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/repositories/settings_repository.dart';

class LocalSettingsRepository implements SettingsRepository {
  const LocalSettingsRepository(this._localDataSource);
  final SettingsLocalDataSource _localDataSource;

  static const _source = 'LocalSettingsRepository';

  @override
  Stream<AppSettings> watch() => _localDataSource.watchSettings().map(
    (row) => row?.toEntity() ?? const AppSettings(),
  );

  @override
  Future<Result<AppSettings>> get() => guardStorage(
    _source,
    () async =>
        (await _localDataSource.getSettings())?.toEntity() ??
        const AppSettings(),
  );

  @override
  Future<Result<void>> save(AppSettings settings) => guardStorage(
    _source,
    () => _localDataSource.saveSettings(settings.toCompanion()),
  );
}

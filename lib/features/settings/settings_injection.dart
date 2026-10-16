import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:exhale/features/settings/data/repositories/local_settings_repository.dart';
import 'package:exhale/features/settings/domain/repositories/settings_repository.dart';
import 'package:exhale/features/settings/domain/usecases/save_settings.dart';
import 'package:get_it/get_it.dart';

void initSettingsDependencies(GetIt getIt) {
  getIt
    ..registerLazySingleton<SettingsLocalDataSource>(
      () => SettingsLocalDataSource(getIt<AppDatabase>()),
    )
    ..registerLazySingleton<SettingsRepository>(
      () => LocalSettingsRepository(getIt<SettingsLocalDataSource>()),
    )
    ..registerFactory(() => SaveSettings(getIt<SettingsRepository>()));
}

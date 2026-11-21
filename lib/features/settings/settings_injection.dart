import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:exhale/features/settings/data/plugin_about_launcher.dart';
import 'package:exhale/features/settings/data/repositories/local_settings_repository.dart';
import 'package:exhale/features/settings/domain/repositories/about_launcher.dart';
import 'package:exhale/features/settings/domain/repositories/settings_repository.dart';
import 'package:exhale/features/settings/domain/usecases/save_settings.dart';
import 'package:get_it/get_it.dart';

void initSettingsDependencies(GetIt getIt, AboutLauncher? about) {
  getIt
    ..registerLazySingleton<SettingsLocalDataSource>(
      () => SettingsLocalDataSource(getIt<AppDatabase>()),
    )
    ..registerLazySingleton<SettingsRepository>(
      () => LocalSettingsRepository(getIt<SettingsLocalDataSource>()),
    )
    ..registerFactory(() => SaveSettings(getIt<SettingsRepository>()))
    ..registerLazySingleton<AboutLauncher>(
      () => about ?? PluginAboutLauncher(),
    );
}

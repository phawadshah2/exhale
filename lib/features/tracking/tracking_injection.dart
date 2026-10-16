import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/core/domain/time/clock.dart';
import 'package:exhale/features/tracking/data/datasources/smoke_log_local_data_source.dart';
import 'package:exhale/features/tracking/data/repositories/local_smoke_log_repository.dart';
import 'package:exhale/features/tracking/domain/repositories/smoke_log_repository.dart';
import 'package:exhale/features/tracking/domain/usecases/delete_smoke_log.dart';
import 'package:exhale/features/tracking/domain/usecases/log_smoke.dart';
import 'package:exhale/features/tracking/domain/usecases/update_smoke_log.dart';
import 'package:get_it/get_it.dart';

void initTrackingDependencies(GetIt getIt) {
  getIt
    ..registerLazySingleton<SmokeLogLocalDataSource>(
      () => SmokeLogLocalDataSource(getIt<AppDatabase>()),
    )
    ..registerLazySingleton<SmokeLogRepository>(
      () => LocalSmokeLogRepository(getIt<SmokeLogLocalDataSource>()),
    )
    ..registerFactory(
      () => LogSmoke(getIt<SmokeLogRepository>(), getIt<Clock>()),
    )
    ..registerFactory(
      () => UpdateSmokeLog(getIt<SmokeLogRepository>(), getIt<Clock>()),
    )
    ..registerFactory(() => DeleteSmokeLog(getIt<SmokeLogRepository>()));
}

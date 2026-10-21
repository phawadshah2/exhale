import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/core/domain/time/clock.dart';
import 'package:exhale/features/tracking/data/datasources/habit_log_local_data_source.dart';
import 'package:exhale/features/tracking/data/repositories/local_habit_log_repository.dart';
import 'package:exhale/features/tracking/domain/repositories/habit_log_repository.dart';
import 'package:exhale/features/tracking/domain/usecases/add_habit_log.dart';
import 'package:exhale/features/tracking/domain/usecases/delete_habit_log.dart';
import 'package:exhale/features/tracking/domain/usecases/update_habit_log.dart';
import 'package:get_it/get_it.dart';

void initTrackingDependencies(GetIt getIt) {
  getIt
    ..registerLazySingleton<HabitLogLocalDataSource>(
      () => HabitLogLocalDataSource(getIt<AppDatabase>()),
    )
    ..registerLazySingleton<HabitLogRepository>(
      () => LocalHabitLogRepository(getIt<HabitLogLocalDataSource>()),
    )
    ..registerFactory(
      () => AddHabitLog(getIt<HabitLogRepository>(), getIt<Clock>()),
    )
    ..registerFactory(
      () => UpdateHabitLog(getIt<HabitLogRepository>(), getIt<Clock>()),
    )
    ..registerFactory(() => DeleteHabitLog(getIt<HabitLogRepository>()));
}

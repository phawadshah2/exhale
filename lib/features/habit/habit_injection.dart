import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/core/domain/time/clock.dart';
import 'package:exhale/core/domain/transaction/transaction_runner.dart';
import 'package:exhale/features/habit/data/datasources/habit_local_data_source.dart';
import 'package:exhale/features/habit/data/repositories/local_habit_repository.dart';
import 'package:exhale/features/habit/domain/repositories/habit_repository.dart';
import 'package:exhale/features/habit/domain/usecases/add_habit.dart';
import 'package:exhale/features/habit/domain/usecases/archive_habit.dart';
import 'package:exhale/features/habit/domain/usecases/start_tracking.dart';
import 'package:exhale/features/habit/domain/usecases/update_habit.dart';
import 'package:exhale/features/plan/domain/usecases/save_plan.dart';
import 'package:get_it/get_it.dart';

void initHabitDependencies(GetIt getIt) {
  getIt
    ..registerLazySingleton<HabitLocalDataSource>(
      () => HabitLocalDataSource(getIt<AppDatabase>()),
    )
    ..registerLazySingleton<HabitRepository>(
      () => LocalHabitRepository(getIt<HabitLocalDataSource>()),
    )
    ..registerFactory(() => AddHabit(getIt<HabitRepository>(), getIt<Clock>()))
    ..registerFactory(() => UpdateHabit(getIt<HabitRepository>()))
    ..registerFactory(
      () => ArchiveHabit(getIt<HabitRepository>(), getIt<Clock>()),
    )
    ..registerFactory(
      () => StartTracking(
        getIt<AddHabit>(),
        getIt<SavePlan>(),
        getIt<TransactionRunner>(),
      ),
    );
}

import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/features/plan/data/datasources/plan_local_data_source.dart';
import 'package:exhale/features/plan/data/datasources/stage_check_local_data_source.dart';
import 'package:exhale/features/plan/data/repositories/local_plan_repository.dart';
import 'package:exhale/features/plan/data/repositories/local_stage_check_repository.dart';
import 'package:exhale/features/plan/domain/repositories/plan_repository.dart';
import 'package:exhale/features/plan/domain/repositories/stage_check_repository.dart';
import 'package:exhale/features/plan/domain/usecases/save_plan.dart';
import 'package:get_it/get_it.dart';

void initPlanDependencies(GetIt getIt) {
  getIt
    ..registerLazySingleton<PlanLocalDataSource>(
      () => PlanLocalDataSource(getIt<AppDatabase>()),
    )
    ..registerLazySingleton<PlanRepository>(
      () => LocalPlanRepository(getIt<PlanLocalDataSource>()),
    )
    ..registerLazySingleton<StageCheckLocalDataSource>(
      () => StageCheckLocalDataSource(getIt<AppDatabase>()),
    )
    ..registerLazySingleton<StageCheckRepository>(
      () => LocalStageCheckRepository(getIt<StageCheckLocalDataSource>()),
    )
    ..registerFactory(() => SavePlan(getIt<PlanRepository>()));
}

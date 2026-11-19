import 'package:exhale/features/presence/data/presence_channel_repository.dart';
import 'package:exhale/features/presence/domain/repositories/presence_repository.dart';
import 'package:exhale/features/presence/domain/usecases/drain_external_logs.dart';
import 'package:exhale/features/tracking/domain/repositories/habit_log_repository.dart';
import 'package:get_it/get_it.dart';

void initPresenceDependencies(GetIt getIt, PresenceRepository? presence) {
  getIt
    ..registerLazySingleton<PresenceRepository>(
      () => presence ?? PresenceChannelRepository(),
    )
    ..registerFactory(
      () => DrainExternalLogs(
        getIt<HabitLogRepository>(),
        getIt<PresenceRepository>(),
      ),
    );
}

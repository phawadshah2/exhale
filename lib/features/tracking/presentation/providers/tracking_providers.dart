import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/presentation/providers/clock_providers.dart';
import 'package:exhale/features/plan/presentation/providers/plan_providers.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:exhale/features/tracking/domain/entities/daily_progress.dart';
import 'package:exhale/features/tracking/domain/entities/smoke_log.dart';
import 'package:exhale/features/tracking/domain/repositories/smoke_log_repository.dart';
import 'package:exhale/features/tracking/domain/usecases/delete_smoke_log.dart';
import 'package:exhale/features/tracking/domain/usecases/log_smoke.dart';
import 'package:exhale/features/tracking/domain/usecases/update_smoke_log.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

final smokeLogRepositoryProvider = Provider<SmokeLogRepository>(
  (ref) => sl<SmokeLogRepository>(),
);

final logSmokeProvider = Provider<LogSmoke>((ref) => sl<LogSmoke>());

final updateSmokeLogProvider = Provider<UpdateSmokeLog>(
  (ref) => sl<UpdateSmokeLog>(),
);

final deleteSmokeLogProvider = Provider<DeleteSmokeLog>(
  (ref) => sl<DeleteSmokeLog>(),
);

/// The logical day it is now, under the user's reset hour.
final todayProvider = Provider<LogicalDay>((ref) {
  final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider).now();
  return ref.watch(dayBoundaryProvider).dayOf(now);
});

final StreamProviderFamily<List<SmokeLog>, LogicalDay> logsForDayProvider =
    StreamProvider.autoDispose.family<List<SmokeLog>, LogicalDay>((ref, day) {
      final boundary = ref.watch(dayBoundaryProvider);
      return ref
          .watch(smokeLogRepositoryProvider)
          .watchLogs(from: boundary.startOf(day), to: boundary.endOf(day));
    });

final latestLogProvider = StreamProvider<SmokeLog?>(
  (ref) => ref.watch(smokeLogRepositoryProvider).watchLatest(),
);

/// Today's count against today's limit; null before a plan exists.
final todayProgressProvider = FutureProvider<DailyProgress?>((ref) async {
  final day = ref.watch(todayProvider);
  final history = await ref.watch(planHistoryProvider.future);
  if (history == null) return null;
  final logs = await ref.watch(logsForDayProvider(day).future);
  return DailyProgress(
    day: day,
    count: logs.length,
    limit: history.limitOn(day),
  );
});

import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/features/tracking/domain/entities/smoke_log.dart';
import 'package:exhale/features/tracking/domain/entities/smoke_trigger.dart';

abstract interface class SmokeLogRepository {
  Future<Result<SmokeLog>> addLog({
    required DateTime loggedAt,
    SmokeTrigger? trigger,
    String? note,
  });

  Future<Result<void>> updateLog(SmokeLog log);

  Future<Result<void>> deleteLog(int id);

  /// Logs with `from <= loggedAt < to`, oldest first.
  Stream<List<SmokeLog>> watchLogs({
    required DateTime from,
    required DateTime to,
  });

  Stream<SmokeLog?> watchLatest();
}

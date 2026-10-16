import 'package:exhale/core/data/storage_guard.dart';
import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/features/tracking/data/datasources/smoke_log_local_data_source.dart';
import 'package:exhale/features/tracking/data/models/smoke_log_model.dart';
import 'package:exhale/features/tracking/domain/entities/smoke_log.dart';
import 'package:exhale/features/tracking/domain/entities/smoke_trigger.dart';
import 'package:exhale/features/tracking/domain/repositories/smoke_log_repository.dart';

class LocalSmokeLogRepository implements SmokeLogRepository {
  const LocalSmokeLogRepository(this._localDataSource);
  final SmokeLogLocalDataSource _localDataSource;

  static const _source = 'LocalSmokeLogRepository';

  @override
  Future<Result<SmokeLog>> addLog({
    required DateTime loggedAt,
    SmokeTrigger? trigger,
    String? note,
  }) => guardStorage(_source, () async {
    final row = await _localDataSource.insertLog(
      smokeLogCompanion(loggedAt: loggedAt, trigger: trigger, note: note),
    );
    return row.toEntity();
  });

  @override
  Future<Result<void>> updateLog(SmokeLog log) async {
    final result = await guardStorage(
      _source,
      () => _localDataSource.updateLog(
        log.id,
        smokeLogCompanion(
          loggedAt: log.loggedAt,
          trigger: log.trigger,
          note: log.note,
        ),
      ),
    );
    return _requireRow(result);
  }

  @override
  Future<Result<void>> deleteLog(int id) async => _requireRow(
    await guardStorage(_source, () => _localDataSource.deleteLog(id)),
  );

  @override
  Stream<List<SmokeLog>> watchLogs({
    required DateTime from,
    required DateTime to,
  }) => _localDataSource
      .watchLogs(from: from, to: to)
      .map((rows) => rows.map((row) => row.toEntity()).toList());

  @override
  Stream<SmokeLog?> watchLatest() =>
      _localDataSource.watchLatest().map((row) => row?.toEntity());

  Result<void> _requireRow(Result<int> result) => switch (result) {
    Success(value: 0) => const FailureResult<void>(NotFoundFailure()),
    Success() => const Success<void>(null),
    FailureResult(:final failure) => FailureResult<void>(failure),
  };
}

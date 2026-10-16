import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/clock.dart';
import 'package:exhale/core/domain/usecase/usecase.dart';
import 'package:exhale/features/tracking/domain/entities/smoke_log.dart';
import 'package:exhale/features/tracking/domain/repositories/smoke_log_repository.dart';
import 'package:exhale/features/tracking/domain/usecases/log_smoke.dart';

class UpdateSmokeLog implements UseCase<void, SmokeLog> {
  const UpdateSmokeLog(this._repository, this._clock);
  final SmokeLogRepository _repository;
  final Clock _clock;

  @override
  Future<Result<void>> call(SmokeLog log) async {
    if (log.loggedAt.isAfter(_clock.now())) {
      return const FailureResult<void>(
        ValidationFailure('A smoke cannot be logged in the future.'),
      );
    }
    return await _repository.updateLog(
      log.copyWith(note: () => normalizeNote(log.note)),
    );
  }
}

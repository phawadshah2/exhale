import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/clock.dart';
import 'package:exhale/core/domain/usecase/usecase.dart';
import 'package:exhale/features/tracking/domain/entities/smoke_log.dart';
import 'package:exhale/features/tracking/domain/entities/smoke_trigger.dart';
import 'package:exhale/features/tracking/domain/repositories/smoke_log_repository.dart';
import 'package:meta/meta.dart';

@immutable
class LogSmokeInput {
  const LogSmokeInput({this.loggedAt, this.trigger, this.note});

  /// Defaults to now; set it to back-fill a missed log.
  final DateTime? loggedAt;
  final SmokeTrigger? trigger;
  final String? note;
}

class LogSmoke implements UseCase<SmokeLog, LogSmokeInput> {
  const LogSmoke(this._repository, this._clock);
  final SmokeLogRepository _repository;
  final Clock _clock;

  @override
  Future<Result<SmokeLog>> call(LogSmokeInput input) async {
    final now = _clock.now();
    final loggedAt = input.loggedAt ?? now;
    if (loggedAt.isAfter(now)) {
      return const FailureResult<SmokeLog>(
        ValidationFailure('A log cannot be in the future.'),
      );
    }
    return await _repository.addLog(
      loggedAt: loggedAt,
      trigger: input.trigger,
      note: normalizeNote(input.note),
    );
  }
}

String? normalizeNote(String? note) {
  final trimmed = note?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/clock.dart';
import 'package:exhale/core/domain/usecase/usecase.dart';
import 'package:exhale/features/tracking/domain/entities/habit_log.dart';
import 'package:exhale/features/tracking/domain/repositories/habit_log_repository.dart';
import 'package:exhale/features/tracking/domain/usecases/add_habit_log.dart';

class UpdateHabitLog implements UseCase<void, HabitLog> {
  const UpdateHabitLog(this._repository, this._clock);
  final HabitLogRepository _repository;
  final Clock _clock;

  @override
  Future<Result<void>> call(HabitLog log) async {
    if (log.loggedAt.isAfter(_clock.now())) {
      return const FailureResult<void>(
        ValidationFailure('A log cannot be in the future.'),
      );
    }
    return await _repository.updateLog(
      log.copyWith(note: () => normalizeNote(log.note)),
    );
  }
}

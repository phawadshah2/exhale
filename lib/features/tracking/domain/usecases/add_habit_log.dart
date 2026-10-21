import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/clock.dart';
import 'package:exhale/core/domain/usecase/usecase.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/tracking/domain/entities/habit_log.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:exhale/features/tracking/domain/repositories/habit_log_repository.dart';
import 'package:meta/meta.dart';

@immutable
class AddHabitLogInput {
  const AddHabitLogInput({
    required this.habitKind,
    this.loggedAt,
    this.trigger,
    this.note,
  });

  final HabitKind habitKind;

  /// Defaults to now; set it to back-fill a missed log.
  final DateTime? loggedAt;
  final Trigger? trigger;
  final String? note;
}

class AddHabitLog implements UseCase<HabitLog, AddHabitLogInput> {
  const AddHabitLog(this._repository, this._clock);
  final HabitLogRepository _repository;
  final Clock _clock;

  @override
  Future<Result<HabitLog>> call(AddHabitLogInput input) async {
    final now = _clock.now();
    final loggedAt = input.loggedAt ?? now;
    if (loggedAt.isAfter(now)) {
      return const FailureResult<HabitLog>(
        ValidationFailure('A log cannot be in the future.'),
      );
    }
    return await _repository.addLog(
      loggedAt: loggedAt,
      habitKind: input.habitKind,
      trigger: input.trigger,
      note: normalizeNote(input.note),
    );
  }
}

String? normalizeNote(String? note) {
  final trimmed = note?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

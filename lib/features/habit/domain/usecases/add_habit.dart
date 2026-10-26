import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/clock.dart';
import 'package:exhale/core/domain/usecase/usecase.dart';
import 'package:exhale/features/habit/domain/entities/habit_draft.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:exhale/features/habit/domain/repositories/habit_repository.dart';
import 'package:exhale/features/habit/domain/validation/habit_validation.dart';

class AddHabit implements UseCase<TrackedHabit, HabitDraft> {
  const AddHabit(this._repository, this._clock);
  final HabitRepository _repository;
  final Clock _clock;

  @override
  Future<Result<TrackedHabit>> call(HabitDraft draft) async {
    final error = HabitValidation.validate(
      priceCents: draft.priceCents,
      unitsPerContainer: draft.unitsPerContainer,
    );
    if (error != null) {
      return FailureResult<TrackedHabit>(ValidationFailure(error));
    }
    return await _repository.add(
      HabitDraft(
        habit: draft.habit,
        reason: HabitValidation.normalizeReason(draft.reason),
        priceCents: draft.priceCents,
        unitsPerContainer: draft.unitsPerContainer,
      ),
      createdAt: _clock.now(),
    );
  }
}

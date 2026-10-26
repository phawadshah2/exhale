import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/usecase/usecase.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:exhale/features/habit/domain/repositories/habit_repository.dart';
import 'package:exhale/features/habit/domain/validation/habit_validation.dart';

class UpdateHabit implements UseCase<void, TrackedHabit> {
  const UpdateHabit(this._repository);
  final HabitRepository _repository;

  @override
  Future<Result<void>> call(TrackedHabit habit) async {
    final error = HabitValidation.validate(
      priceCents: habit.priceCents,
      unitsPerContainer: habit.unitsPerContainer,
    );
    if (error != null) return FailureResult<void>(ValidationFailure(error));
    return await _repository.update(
      habit.copyWith(
        reason: () => HabitValidation.normalizeReason(habit.reason),
      ),
    );
  }
}

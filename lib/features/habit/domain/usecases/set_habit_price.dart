import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/domain/usecase/usecase.dart';
import 'package:exhale/features/habit/domain/repositories/habit_repository.dart';
import 'package:exhale/features/habit/domain/validation/habit_validation.dart';

typedef SetHabitPriceInput = ({
  int habitId,
  LogicalDay day,
  int? priceCents,
  int unitsPerContainer,
});

/// The only way a habit's price or container size changes after it is added.
class SetHabitPrice implements UseCase<void, SetHabitPriceInput> {
  const SetHabitPrice(this._repository);
  final HabitRepository _repository;

  @override
  Future<Result<void>> call(SetHabitPriceInput input) async {
    final error = HabitValidation.validate(
      priceCents: input.priceCents,
      unitsPerContainer: input.unitsPerContainer,
    );
    if (error != null) return FailureResult<void>(ValidationFailure(error));
    return await _repository.setPrice(
      input.habitId,
      day: input.day,
      priceCents: input.priceCents,
      unitsPerContainer: input.unitsPerContainer,
    );
  }
}

import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/clock.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/domain/usecase/usecase.dart';
import 'package:exhale/features/plan/domain/repositories/stage_check_repository.dart';

typedef KeepOriginalDateInput = ({
  int habitId,
  LogicalDay planStartDay,
  LogicalDay windowEndDay,
  LogicalDay holdStart,
});

/// Takes back a hold: deletes it and answers its card, together.
class KeepOriginalDate implements UseCase<void, KeepOriginalDateInput> {
  const KeepOriginalDate(this._checks, this._clock);
  final StageCheckRepository _checks;
  final Clock _clock;

  @override
  Future<Result<void>> call(KeepOriginalDateInput input) =>
      _checks.keepOriginalDate(
        input.habitId,
        input.planStartDay,
        input.windowEndDay,
        input.holdStart,
        _clock.now(),
      );
}

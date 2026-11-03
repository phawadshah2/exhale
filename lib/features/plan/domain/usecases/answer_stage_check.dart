import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/clock.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/core/domain/usecase/usecase.dart';
import 'package:exhale/features/plan/domain/repositories/stage_check_repository.dart';

typedef StageCheckRef = ({
  int habitId,
  LogicalDay planStartDay,
  LogicalDay windowEndDay,
});

/// Marks a check's card as answered now ("Got it").
class AnswerStageCheck implements UseCase<void, StageCheckRef> {
  const AnswerStageCheck(this._checks, this._clock);
  final StageCheckRepository _checks;
  final Clock _clock;

  @override
  Future<Result<void>> call(StageCheckRef input) => _checks.answer(
    input.habitId,
    input.planStartDay,
    input.windowEndDay,
    _clock.now(),
  );
}

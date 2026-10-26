import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/clock.dart';
import 'package:exhale/core/domain/usecase/usecase.dart';
import 'package:exhale/features/habit/domain/repositories/habit_repository.dart';

class ArchiveHabit implements UseCase<void, int> {
  const ArchiveHabit(this._repository, this._clock);
  final HabitRepository _repository;
  final Clock _clock;

  @override
  Future<Result<void>> call(int id) =>
      _repository.archive(id, at: _clock.now());
}

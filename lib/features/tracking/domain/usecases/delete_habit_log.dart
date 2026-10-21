import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/usecase/usecase.dart';
import 'package:exhale/features/tracking/domain/repositories/habit_log_repository.dart';

class DeleteHabitLog implements UseCase<void, int> {
  const DeleteHabitLog(this._repository);
  final HabitLogRepository _repository;

  @override
  Future<Result<void>> call(int id) => _repository.deleteLog(id);
}

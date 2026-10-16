import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/usecase/usecase.dart';
import 'package:exhale/features/tracking/domain/repositories/smoke_log_repository.dart';

class DeleteSmokeLog implements UseCase<void, int> {
  const DeleteSmokeLog(this._repository);
  final SmokeLogRepository _repository;

  @override
  Future<Result<void>> call(int id) => _repository.deleteLog(id);
}

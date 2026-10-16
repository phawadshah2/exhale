import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/usecase/usecase.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/repositories/settings_repository.dart';
import 'package:exhale/features/settings/domain/validation/settings_validation.dart';

class SaveSettings implements UseCase<void, AppSettings> {
  const SaveSettings(this._repository);
  final SettingsRepository _repository;

  @override
  Future<Result<void>> call(AppSettings settings) async {
    final trimmedName = settings.userName?.trim();
    final normalized = settings.copyWith(
      userName: () =>
          trimmedName == null || trimmedName.isEmpty ? null : trimmedName,
    );
    final error = SettingsValidation.validate(normalized);
    if (error != null) {
      return FailureResult<void>(ValidationFailure(error));
    }
    return await _repository.save(normalized);
  }
}

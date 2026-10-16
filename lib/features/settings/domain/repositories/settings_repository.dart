import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';

abstract interface class SettingsRepository {
  /// Emits defaults until settings are first saved.
  Stream<AppSettings> watch();

  Future<Result<AppSettings>> get();

  Future<Result<void>> save(AppSettings settings);
}

import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/repositories/settings_repository.dart';
import 'package:exhale/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter_riverpod/misc.dart';

/// Provider overrides that need storage before the first frame.
Future<List<Override>> startupOverrides() async {
  final settings = switch (await sl<SettingsRepository>().get()) {
    Success(:final value) => value,
    FailureResult() => const AppSettings(),
  };
  return [initialSettingsProvider.overrideWithValue(settings)];
}

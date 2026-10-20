import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/day_boundary.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/entities/theme_preference.dart';
import 'package:exhale/features/settings/domain/repositories/settings_repository.dart';
import 'package:exhale/features/settings/domain/usecases/save_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => sl<SettingsRepository>(),
);

final saveSettingsProvider = Provider<SaveSettings>(
  (ref) => sl<SaveSettings>(),
);

final settingsProvider = StreamProvider<AppSettings>(
  (ref) => ref.watch(settingsRepositoryProvider).watch(),
);

/// Settings read before the first frame (overridden in main), so theme and
/// day boundary are right before the stream's first value arrives.
final initialSettingsProvider = Provider<AppSettings>(
  (ref) => const AppSettings(),
);

/// Latest stored settings, falling back to [initialSettingsProvider].
final currentSettingsProvider = Provider<AppSettings>(
  (ref) =>
      ref.watch(settingsProvider).value ?? ref.watch(initialSettingsProvider),
);

final themeModeProvider = Provider<ThemeMode>(
  (ref) => switch (ref.watch(currentSettingsProvider).themePreference) {
    ThemePreference.light => ThemeMode.light,
    ThemePreference.dark => ThemeMode.dark,
    ThemePreference.system => ThemeMode.system,
  },
);

final habitProvider = Provider<Habit>(
  (ref) => ref.watch(currentSettingsProvider.select((s) => s.habit)),
);

final dayBoundaryProvider = Provider<DayBoundary>(
  (ref) => ref.watch(currentSettingsProvider).dayBoundary,
);

final settingsActionsProvider = Provider<SettingsActions>(SettingsActions.new);

class SettingsActions {
  const SettingsActions(this._ref);
  final Ref _ref;

  /// Applies [change] to the latest stored settings and saves the result.
  Future<Result<void>> update(
    AppSettings Function(AppSettings current) change,
  ) async {
    final current = await _ref.read(settingsRepositoryProvider).get();
    return switch (current) {
      Success(:final value) => await _ref.read(saveSettingsProvider)(
        change(value),
      ),
      FailureResult(:final failure) => FailureResult<void>(failure),
    };
  }
}

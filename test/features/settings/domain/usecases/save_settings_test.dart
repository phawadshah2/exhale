import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:exhale/features/settings/data/repositories/local_settings_repository.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/usecases/save_settings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late LocalSettingsRepository repository;
  late SaveSettings saveSettings;

  setUp(() {
    database = createTestDatabase();
    repository = LocalSettingsRepository(SettingsLocalDataSource(database));
    saveSettings = SaveSettings(repository);
  });

  tearDown(() => database.close());

  Future<AppSettings> stored() async =>
      (await repository.get() as Success<AppSettings>).value;

  test('trims the name and stores blank as null', () async {
    await saveSettings(const AppSettings(userName: '  Fawad '));
    expect((await stored()).userName, 'Fawad');

    await saveSettings(const AppSettings(userName: '   '));
    expect((await stored()).userName, isNull);
  });

  test('rejects invalid values without saving', () async {
    const invalid = [
      AppSettings(dayResetHour: 24),
      AppSettings(dayResetHour: -1),
      AppSettings(accentIndex: -1),
    ];

    for (final settings in invalid) {
      final result = await saveSettings(settings);
      expect(
        (result as FailureResult<void>).failure,
        isA<ValidationFailure>(),
        reason: '$settings',
      );
    }
    expect(await database.select(database.settings).get(), isEmpty);
  });

  test('rejects a name over 40 characters', () async {
    final result = await saveSettings(AppSettings(userName: 'x' * 41));

    expect((result as FailureResult<void>).failure, isA<ValidationFailure>());
  });
}

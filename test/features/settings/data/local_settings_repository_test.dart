import 'package:drift/drift.dart' hide isNull;
import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:exhale/features/settings/data/repositories/local_settings_repository.dart';
import 'package:exhale/features/settings/domain/entities/app_icon_choice.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/entities/theme_preference.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late LocalSettingsRepository repository;

  setUp(() {
    database = createTestDatabase();
    repository = LocalSettingsRepository(SettingsLocalDataSource(database));
  });

  tearDown(() => database.close());

  AppSettings valueOf(Result<AppSettings> result) =>
      (result as Success<AppSettings>).value;

  test('returns defaults before anything is saved', () async {
    expect(valueOf(await repository.get()), const AppSettings());
    expect(await repository.watch().first, const AppSettings());
  });

  test('saves and reads back every field', () async {
    const settings = AppSettings(
      userName: 'Fawad',
      dayResetHour: 5,
      themePreference: ThemePreference.light,
      accentIndex: 2,
      appIcon: AppIconChoice.ember,
      priceCents: 1450,
      unitsPerContainer: 25,
      currencySymbol: 'AED',
    );

    await repository.save(settings);

    expect(valueOf(await repository.get()), settings);
  });

  test('saving twice keeps a single row', () async {
    await repository.save(const AppSettings(userName: 'A'));
    await repository.save(const AppSettings(userName: 'B'));

    expect(await database.select(database.settings).get(), hasLength(1));
    expect(valueOf(await repository.get()).userName, 'B');
  });

  test('can clear optional fields', () async {
    await repository.save(const AppSettings(priceCents: 1450));
    final cleared = valueOf(await repository.get())
        .copyWith(priceCents: () => null);
    await repository.save(cleared);

    expect(valueOf(await repository.get()).priceCents, isNull);
  });

  test('unknown stored enum names fall back to defaults', () async {
    await database
        .into(database.settings)
        .insert(
          const SettingsCompanion(
            themePreference: Value('neon'),
            appIcon: Value('unicorn'),
          ),
        );

    final settings = valueOf(await repository.get());

    expect(settings.themePreference, ThemePreference.system);
    expect(settings.appIcon, AppIconChoice.breath);
  });
}

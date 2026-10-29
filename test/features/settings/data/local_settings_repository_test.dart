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
      currencySymbol: 'AED',
      askForTrigger: false,
      triggerPromptIntroSeen: true,
      logHintSeen: true,
    );

    await repository.save(settings);

    expect(valueOf(await repository.get()), settings);
  });

  test('saves and reads back wake and bed times', () async {
    await repository.save(const AppSettings(wakeMinute: 420, bedMinute: 60));

    final settings = valueOf(await repository.get());
    expect(settings.wakeMinute, 420);
    expect(settings.bedMinute, 60);
  });

  test('wake and bed times are unset by default', () async {
    await repository.save(const AppSettings());

    final settings = valueOf(await repository.get());
    expect(settings.wakeMinute, isNull);
    expect(settings.bedMinute, isNull);
    expect(settings.dayWindow, isNull);
  });

  test('can clear wake and bed times', () async {
    await repository.save(const AppSettings(wakeMinute: 420, bedMinute: 60));
    final cleared = valueOf(await repository.get())
        .copyWith(wakeMinute: () => null, bedMinute: () => null);
    await repository.save(cleared);

    expect(valueOf(await repository.get()).dayWindow, isNull);
  });

  test('saving twice keeps a single row', () async {
    await repository.save(const AppSettings(userName: 'A'));
    await repository.save(const AppSettings(userName: 'B'));

    expect(await database.select(database.settings).get(), hasLength(1));
    expect(valueOf(await repository.get()).userName, 'B');
  });

  test('can clear optional fields', () async {
    await repository.save(const AppSettings(userName: 'Fawad'));
    final cleared = valueOf(await repository.get())
        .copyWith(userName: () => null);
    await repository.save(cleared);

    expect(valueOf(await repository.get()).userName, isNull);
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

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:exhale/features/settings/data/repositories/local_settings_repository.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v1 → v2 keeps settings and turns glass effects on', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final database = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw
            ..execute(r'''
              CREATE TABLE "settings" (
                "id" INTEGER NOT NULL DEFAULT 1,
                "user_name" TEXT NULL,
                "day_reset_hour" INTEGER NOT NULL DEFAULT 4,
                "theme_preference" TEXT NOT NULL DEFAULT 'dark',
                "accent_index" INTEGER NOT NULL DEFAULT 0,
                "app_icon" TEXT NOT NULL DEFAULT 'breath',
                "pack_price_cents" INTEGER NULL,
                "cigarettes_per_pack" INTEGER NOT NULL DEFAULT 20,
                "currency_symbol" TEXT NOT NULL DEFAULT '$',
                PRIMARY KEY ("id"))''')
            ..execute(
              'INSERT INTO settings (id, user_name, pack_price_cents) '
              "VALUES (1, 'Fawad', 1450)",
            )
            ..execute('PRAGMA user_version = 1');
        },
      ),
    );
    addTearDown(database.close);

    final repository = LocalSettingsRepository(
      SettingsLocalDataSource(database),
    );
    final settings = (await repository.get() as Success<AppSettings>).value;

    expect(settings.userName, 'Fawad');
    expect(settings.packPriceCents, 1450);
    expect(settings.glassEffects, isTrue);
    expect(
      await database.customSelect('PRAGMA user_version').getSingle(),
      isA<QueryRow>().having((r) => r.data.values.single, 'version', 2),
    );
  });
}

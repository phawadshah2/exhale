import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/plan/data/datasources/plan_local_data_source.dart';
import 'package:exhale/features/plan/data/repositories/local_plan_repository.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:exhale/features/settings/data/repositories/local_settings_repository.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// Tables as they were before v3 (v1 settings lack glass_effects).
void _createLegacySchema(sqlite.Database raw, {required int version}) {
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
    ..execute('''
      CREATE TABLE "plans" (
        "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        "start_day" TEXT NOT NULL UNIQUE,
        "start_limit" INTEGER NOT NULL,
        "step_days" INTEGER NOT NULL,
        "target_limit" INTEGER NOT NULL,
        "created_at" INTEGER NOT NULL
          DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)))''');
  if (version >= 2) {
    raw.execute(
      'ALTER TABLE settings ADD COLUMN "glass_effects" INTEGER NOT NULL '
      'DEFAULT 1 CHECK ("glass_effects" IN (0, 1))',
    );
  }
  raw
    ..execute(
      'INSERT INTO settings (id, user_name, pack_price_cents) '
      "VALUES (1, 'Fawad', 1450)",
    )
    ..execute(
      'INSERT INTO plans (start_day, start_limit, step_days, target_limit) '
      "VALUES ('2026-10-16', 9, 7, 0), ('2026-11-20', 5, 3, 1)",
    )
    ..execute('PRAGMA user_version = $version');
}

AppDatabase _openLegacy(int version) {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(
    NativeDatabase.memory(
      setup: (raw) => _createLegacySchema(raw, version: version),
    ),
  );
}

void main() {
  for (final version in [1, 2]) {
    group('upgrade from v$version', () {
      late AppDatabase database;

      setUp(() => database = _openLegacy(version));
      tearDown(() => database.close());

      test('keeps settings; trigger prompt on', () async {
        final settings =
            (await LocalSettingsRepository(SettingsLocalDataSource(database))
                        .get()
                    as Success<AppSettings>)
                .value;

        expect(settings.userName, 'Fawad');
        expect(settings.packPriceCents, 1450);
        expect(settings.askForTrigger, isTrue);
        expect(settings.triggerPromptIntroSeen, isFalse);
      });

      test('turns step plans into quit dates', () async {
        final history =
            (await LocalPlanRepository(PlanLocalDataSource(database))
                        .getHistory()
                    as Success<PlanHistory?>)
                .value!;

        // 9/day, -1 every 7 days to 0: reached 0 on 18 Dec.
        expect(history.plans.first.quitDay, LogicalDay(2026, 12, 18));
        // 5/day, -1 every 3 days to 1: reached its target on 2 Dec.
        expect(history.plans.last.quitDay, LogicalDay(2026, 12, 2));

        // The converted 9/day plan keeps the same weekly limits.
        final plan = history.plans.first;
        expect(plan.limitOn(LogicalDay(2026, 10, 22)), 9);
        expect(plan.limitOn(LogicalDay(2026, 10, 23)), 8);
        expect(plan.stageCount, 9);
      });

      test('ends on schema v5 without glass_effects', () async {
        final row = await database
            .customSelect('PRAGMA user_version')
            .getSingle();
        expect(row.data.values.single, 5);
        final columns = await database
            .customSelect('PRAGMA table_info(settings)')
            .get();
        expect(
          columns.map((c) => c.data['name']),
          isNot(contains('glass_effects')),
        );
      });
    });
  }
}

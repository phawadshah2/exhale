import 'dart:io';

import 'package:drift/drift.dart' hide Trigger, isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/habit/data/datasources/habit_local_data_source.dart';
import 'package:exhale/features/habit/data/repositories/local_habit_repository.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:exhale/features/plan/data/datasources/plan_local_data_source.dart';
import 'package:exhale/features/plan/data/repositories/local_plan_repository.dart';
import 'package:exhale/features/plan/domain/entities/plan_history.dart';
import 'package:exhale/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:exhale/features/settings/data/repositories/local_settings_repository.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/tracking/data/datasources/habit_log_local_data_source.dart';
import 'package:exhale/features/tracking/data/repositories/local_habit_log_repository.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

const _legacySmokeLogs = '''
  CREATE TABLE "smoke_logs" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "logged_at" INTEGER NOT NULL,
    "trigger" TEXT NULL,
    "note" TEXT NULL,
    "created_at" INTEGER NOT NULL
      DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)))''';

const _legacySmokeLogsIndex =
    'CREATE INDEX idx_smoke_logs_logged_at ON smoke_logs (logged_at)';

const _v7Plans = '''
  CREATE TABLE "plans" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "start_day" TEXT NOT NULL UNIQUE,
    "start_limit" INTEGER NOT NULL,
    "quit_day" TEXT NOT NULL,
    "created_at" INTEGER NOT NULL
      DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)))''';

/// 16 Oct 2026, 09:00 local, as drift stores it (unix seconds).
final int _legacyLogSeconds =
    DateTime(2026, 10, 16, 9).millisecondsSinceEpoch ~/ 1000;

void _insertLegacyLog(sqlite.Database raw) => raw.execute(
  'INSERT INTO smoke_logs (logged_at, trigger, note) '
  "VALUES ($_legacyLogSeconds, 'coffee', 'after lunch')",
);

AppDatabase _open(void Function(sqlite.Database raw) setup) {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory(setup: setup));
}

Future<List<Map<String, Object?>>> _rows(AppDatabase db, String sql) async =>
    (await db.customSelect(sql).get()).map((row) => row.data).toList();

Future<List<TrackedHabit>> _activeHabits(AppDatabase db) async =>
    (await LocalHabitRepository(HabitLocalDataSource(db)).getActive()
            as Success<List<TrackedHabit>>)
        .value;

Future<AppSettings> _settings(AppDatabase db) async =>
    (await LocalSettingsRepository(SettingsLocalDataSource(db)).get()
            as Success<AppSettings>)
        .value;

Future<PlanHistory> _history(AppDatabase db, int habitId) async =>
    (await LocalPlanRepository(
      PlanLocalDataSource(db),
    ).getHistory(habitId) as Success<PlanHistory?>).value!;

/// Columns of every table, by name, and every index, ignoring column order.
Future<Map<String, Object?>> _schema(AppDatabase db) async {
  final tables = (await _rows(
    db,
    "SELECT name FROM sqlite_master WHERE type = 'table' "
    "AND name NOT LIKE 'sqlite_%' ORDER BY name",
  )).map((t) => t['name']! as String);
  return {
    for (final table in tables)
      table: {
        for (final c in await _rows(db, 'PRAGMA table_info($table)'))
          c['name']: [c['type'], c['notnull'], c['dflt_value'], c['pk']],
      },
    'indexes': (await _rows(
      db,
      "SELECT name, tbl_name FROM sqlite_master WHERE type = 'index'",
    )).map((i) => '${i['tbl_name']}.${i['name']}').toSet(),
  };
}

/// Every upgrade ends on v9 with the fresh install's schema, consistent
/// foreign keys and no moved columns left in settings.
Future<void> _expectLatest(AppDatabase database) async {
  final [version] = await _rows(database, 'PRAGMA user_version');
  expect(version.values.single, 9);
  expect(await _rows(database, 'PRAGMA foreign_key_check'), isEmpty);

  final fresh = _open((_) {});
  addTearDown(fresh.close);
  expect(await _schema(database), await _schema(fresh));

  final settingsColumns = (await _rows(
    database,
    'PRAGMA table_info(settings)',
  )).map((c) => c['name']);
  expect(
    settingsColumns,
    containsAll(['log_hint_seen', 'wake_minute', 'bed_minute']),
  );
  expect(
    settingsColumns,
    allOf(
      isNot(contains('glass_effects')),
      isNot(contains('habit_kind')),
      isNot(contains('reason')),
      isNot(contains('price_cents')),
      isNot(contains('pack_price_cents')),
      isNot(contains('units_per_container')),
    ),
  );
  final logColumns = (await _rows(
    database,
    'PRAGMA table_info(habit_logs)',
  )).map((c) => c['name']);
  expect(
    logColumns,
    allOf(contains('habit_id'), isNot(contains('habit_kind'))),
  );

  final tables = (await _rows(
    database,
    "SELECT name FROM sqlite_master WHERE type = 'table'",
  )).map((t) => t['name']);
  expect(tables, allOf(contains('habit_logs'), isNot(contains('smoke_logs'))));
  final indexes = (await _rows(
    database,
    "SELECT name FROM sqlite_master WHERE type = 'index'",
  )).map((i) => i['name']);
  expect(
    indexes,
    allOf(
      contains('idx_habit_logs_logged_at'),
      contains('idx_habit_logs_habit_id_logged_at'),
      isNot(contains('idx_smoke_logs_logged_at')),
    ),
  );
}

/// The legacy log, now on habit 1.
Future<void> _expectLegacyLogOnHabitOne(AppDatabase database) async {
  final logs = await LocalHabitLogRepository(HabitLogLocalDataSource(database))
      .watchLogs(habitId: 1, from: DateTime(2026), to: DateTime(2027))
      .first;
  expect(logs, hasLength(1));
  expect(logs.single.habitId, 1);
  expect(logs.single.loggedAt, DateTime(2026, 10, 16, 9));
  expect(logs.single.trigger, Trigger.coffee);
  expect(logs.single.note, 'after lunch');
}

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
    ..execute(_legacySmokeLogs)
    ..execute(_legacySmokeLogsIndex)
    ..execute(
      'INSERT INTO settings (id, user_name, pack_price_cents) '
      "VALUES (1, 'Fawad', 1450)",
    )
    ..execute(
      'INSERT INTO plans (start_day, start_limit, step_days, target_limit) '
      "VALUES ('2026-10-16', 9, 7, 0), ('2026-11-20', 5, 3, 1)",
    )
    ..execute('PRAGMA user_version = $version');
  _insertLegacyLog(raw);
}

/// v3 settings (glass effects, no trigger settings until v4), quit-date
/// plans and smoke_logs.
void _createV3Schema(sqlite.Database raw, {required int version}) {
  raw
    ..execute(r'''
      CREATE TABLE "settings" (
        "id" INTEGER NOT NULL DEFAULT 1,
        "user_name" TEXT NULL,
        "day_reset_hour" INTEGER NOT NULL DEFAULT 4,
        "theme_preference" TEXT NOT NULL DEFAULT 'system',
        "accent_index" INTEGER NOT NULL DEFAULT 0,
        "app_icon" TEXT NOT NULL DEFAULT 'breath',
        "pack_price_cents" INTEGER NULL,
        "cigarettes_per_pack" INTEGER NOT NULL DEFAULT 20,
        "glass_effects" INTEGER NOT NULL DEFAULT 1
          CHECK ("glass_effects" IN (0, 1)),
        "currency_symbol" TEXT NOT NULL DEFAULT '$',
        PRIMARY KEY ("id"))''')
    ..execute(_v7Plans)
    ..execute(_legacySmokeLogs)
    ..execute(_legacySmokeLogsIndex)
    ..execute(
      'INSERT INTO settings (id, user_name, pack_price_cents, '
      "cigarettes_per_pack) VALUES (1, 'Fawad', 1200, 25)",
    )
    ..execute(
      'INSERT INTO plans (start_day, start_limit, quit_day) '
      "VALUES ('2026-10-16', 9, '2026-12-18')",
    );
  if (version >= 4) {
    raw
      ..execute(
        'ALTER TABLE settings ADD COLUMN "ask_for_trigger" INTEGER NOT NULL '
        'DEFAULT 1 CHECK ("ask_for_trigger" IN (0, 1))',
      )
      ..execute(
        'ALTER TABLE settings ADD COLUMN "trigger_prompt_intro_seen" '
        'INTEGER NOT NULL DEFAULT 0 '
        'CHECK ("trigger_prompt_intro_seen" IN (0, 1))',
      )
      ..execute(
        'UPDATE settings SET ask_for_trigger = 0, '
        'trigger_prompt_intro_seen = 1',
      );
  }
  raw.execute('PRAGMA user_version = $version');
  _insertLegacyLog(raw);
}

/// The v7 schema, built by hand for cases the fixture does not cover.
void _createV7Schema(
  sqlite.Database raw, {
  String? settingsValues,
  List<String> logKinds = const [],
  bool withPlan = true,
}) {
  raw
    ..execute(r'''
      CREATE TABLE "settings" (
        "id" INTEGER NOT NULL DEFAULT 1,
        "user_name" TEXT NULL,
        "day_reset_hour" INTEGER NOT NULL DEFAULT 4,
        "theme_preference" TEXT NOT NULL DEFAULT 'system',
        "accent_index" INTEGER NOT NULL DEFAULT 0,
        "app_icon" TEXT NOT NULL DEFAULT 'breath',
        "price_cents" INTEGER NULL,
        "units_per_container" INTEGER NOT NULL DEFAULT 20,
        "ask_for_trigger" INTEGER NOT NULL DEFAULT 1,
        "trigger_prompt_intro_seen" INTEGER NOT NULL DEFAULT 0,
        "currency_symbol" TEXT NOT NULL DEFAULT '$',
        "habit_kind" TEXT NOT NULL DEFAULT 'smoking',
        "custom_habit_name" TEXT NULL,
        "custom_habit_unit" TEXT NULL,
        "reason" TEXT NULL,
        PRIMARY KEY ("id"))''')
    ..execute(_v7Plans)
    ..execute('''
      CREATE TABLE "habit_logs" (
        "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        "logged_at" INTEGER NOT NULL,
        "trigger" TEXT NULL,
        "note" TEXT NULL,
        "created_at" INTEGER NOT NULL
          DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
        "habit_kind" TEXT NOT NULL DEFAULT 'smoking')''')
    ..execute(
      'CREATE INDEX idx_habit_logs_logged_at ON habit_logs (logged_at)',
    );
  if (settingsValues != null) {
    raw.execute(
      'INSERT INTO settings (id, habit_kind, custom_habit_name, '
      'custom_habit_unit, reason, price_cents, units_per_container) '
      'VALUES $settingsValues',
    );
  }
  if (withPlan) {
    raw.execute(
      'INSERT INTO plans (start_day, start_limit, quit_day) '
      "VALUES ('2026-10-16', 9, '2026-12-18')",
    );
  }
  for (final (index, kind) in logKinds.indexed) {
    raw.execute(
      'INSERT INTO habit_logs (logged_at, habit_kind) '
      "VALUES (${_legacyLogSeconds + index * 60}, '$kind')",
    );
  }
  raw.execute('PRAGMA user_version = 7');
}

void main() {
  for (final version in [1, 2]) {
    group('upgrade from v$version', () {
      late AppDatabase database;

      setUp(
        () => database = _open(
          (raw) => _createLegacySchema(raw, version: version),
        ),
      );
      tearDown(() => database.close());

      test('ends on v9', () => _expectLatest(database));

      test('keeps settings; trigger prompt on', () async {
        final settings = await _settings(database);

        expect(settings.userName, 'Fawad');
        expect(settings.askForTrigger, isTrue);
        expect(settings.triggerPromptIntroSeen, isFalse);
        expect(settings.logHintSeen, isFalse);
      });

      test('the price moves to a smoking habit 1', () async {
        final [habit] = await _activeHabits(database);

        expect(habit.id, 1);
        expect(habit.habit, Habit.smoking);
        expect(habit.priceCents, 1450);
        expect(habit.unitsPerContainer, 20);
        expect(habit.reason, isNull);
      });

      test('turns step plans into quit dates on habit 1', () async {
        final history = await _history(database, 1);

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

      test('renames smoke_logs and moves its log to habit 1', () async {
        await _expectLegacyLogOnHabitOne(database);
      });
    });
  }

  for (final version in [3, 4]) {
    group('upgrade from v$version', () {
      late AppDatabase database;

      setUp(
        () => database = _open((raw) => _createV3Schema(raw, version: version)),
      );
      tearDown(() => database.close());

      test('ends on v9', () => _expectLatest(database));

      test('keeps settings and trigger settings', () async {
        final settings = await _settings(database);
        expect(settings.userName, 'Fawad');
        expect(settings.askForTrigger, version < 4);
        expect(settings.triggerPromptIntroSeen, version >= 4);
        expect(settings.wakeMinute, isNull);
        expect(settings.bedMinute, isNull);
      });

      test('the price and plan move to a smoking habit 1', () async {
        final [habit] = await _activeHabits(database);
        expect(habit.habit, Habit.smoking);
        expect(habit.priceCents, 1200);
        expect(habit.unitsPerContainer, 25);

        final [plan] = (await _history(database, 1)).plans;
        expect(plan.startDay, LogicalDay(2026, 10, 16));
        expect(plan.quitDay, LogicalDay(2026, 12, 18));
      });

      test(
        'renames smoke_logs and moves its log to habit 1',
        () => _expectLegacyLogOnHabitOne(database),
      );
    });
  }

  group('upgrade from v5', () {
    late AppDatabase database;

    setUp(
      () => database = _open((raw) {
        raw
          ..execute(r'''
            CREATE TABLE "settings" (
              "id" INTEGER NOT NULL DEFAULT 1,
              "user_name" TEXT NULL,
              "day_reset_hour" INTEGER NOT NULL DEFAULT 4,
              "theme_preference" TEXT NOT NULL DEFAULT 'system',
              "accent_index" INTEGER NOT NULL DEFAULT 0,
              "app_icon" TEXT NOT NULL DEFAULT 'breath',
              "pack_price_cents" INTEGER NULL,
              "cigarettes_per_pack" INTEGER NOT NULL DEFAULT 20,
              "ask_for_trigger" INTEGER NOT NULL DEFAULT 1,
              "trigger_prompt_intro_seen" INTEGER NOT NULL DEFAULT 0,
              "currency_symbol" TEXT NOT NULL DEFAULT '$',
              PRIMARY KEY ("id"))''')
          ..execute(_v7Plans)
          ..execute(_legacySmokeLogs)
          ..execute(_legacySmokeLogsIndex)
          ..execute(
            'INSERT INTO settings (id, user_name, ask_for_trigger, '
            'pack_price_cents, cigarettes_per_pack) '
            "VALUES (1, 'Fawad', 0, 900, 30)",
          )
          ..execute(
            'INSERT INTO plans (start_day, start_limit, quit_day) '
            "VALUES ('2026-10-16', 9, '2026-12-18')",
          )
          ..execute('PRAGMA user_version = 5');
        _insertLegacyLog(raw);
      }),
    );
    tearDown(() => database.close());

    test('ends on v9', () => _expectLatest(database));

    test('keeps settings; price and pack size move to habit 1', () async {
      expect((await _settings(database)).askForTrigger, isFalse);

      final [habit] = await _activeHabits(database);
      expect(habit.habit, Habit.smoking);
      expect(habit.priceCents, 900);
      expect(habit.unitsPerContainer, 30);
    });

    test('moves its log to habit 1', () async {
      await _expectLegacyLogOnHabitOne(database);
    });
  });

  group('upgrade from v6', () {
    late AppDatabase database;

    setUp(
      () => database = _open((raw) {
        raw
          ..execute(r'''
            CREATE TABLE "settings" (
              "id" INTEGER NOT NULL DEFAULT 1,
              "user_name" TEXT NULL,
              "day_reset_hour" INTEGER NOT NULL DEFAULT 4,
              "theme_preference" TEXT NOT NULL DEFAULT 'system',
              "accent_index" INTEGER NOT NULL DEFAULT 0,
              "app_icon" TEXT NOT NULL DEFAULT 'breath',
              "pack_price_cents" INTEGER NULL,
              "cigarettes_per_pack" INTEGER NOT NULL DEFAULT 20,
              "ask_for_trigger" INTEGER NOT NULL DEFAULT 1,
              "trigger_prompt_intro_seen" INTEGER NOT NULL DEFAULT 0,
              "currency_symbol" TEXT NOT NULL DEFAULT '$',
              "habit_kind" TEXT NOT NULL DEFAULT 'smoking',
              "custom_habit_name" TEXT NULL,
              "custom_habit_unit" TEXT NULL,
              "reason" TEXT NULL,
              PRIMARY KEY ("id"))''')
          ..execute(_v7Plans)
          ..execute(_legacySmokeLogs)
          ..execute(_legacySmokeLogsIndex)
          ..execute(
            'INSERT INTO settings (id, habit_kind, reason, '
            'pack_price_cents, cigarettes_per_pack) '
            "VALUES (1, 'vaping', 'Breathe', 1200, 30)",
          )
          ..execute(
            'INSERT INTO plans (start_day, start_limit, quit_day) '
            "VALUES ('2026-10-16', 12, '2027-01-08')",
          )
          ..execute('PRAGMA user_version = 6');
        _insertLegacyLog(raw);
      }),
    );
    tearDown(() => database.close());

    test('ends on v9', () => _expectLatest(database));

    test('the habit, reason and price move to habit 1', () async {
      final [habit] = await _activeHabits(database);
      expect(habit.habit, Habit.vaping);
      expect(habit.reason, 'Breathe');
      expect(habit.priceCents, 1200);
      expect(habit.unitsPerContainer, 30);
    });

    test('its log, untyped before v7, goes to habit 1', () async {
      await _expectLegacyLogOnHabitOne(database);
    });
  });

  group('upgrade from v7', () {
    test('a real v7 database keeps the habit, plans and logs', () async {
      final dir = Directory.systemTemp.createTempSync('exhale_v7');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('test/fixtures/exhale_v7.sqlite')
          .copySync('${dir.path}/exhale.sqlite');
      final before = sqlite.sqlite3.open(file.path);
      final planCount = before.select('SELECT * FROM plans').length;
      final logCount = before.select('SELECT * FROM habit_logs').length;
      final settingsKind =
          before.select('SELECT habit_kind FROM settings').single['habit_kind']
              as String;
      before.close();

      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final database = AppDatabase(NativeDatabase(file));
      addTearDown(database.close);

      await _expectLatest(database);
      final [habit] = await _activeHabits(database);
      expect(habit.id, 1);
      expect(habit.habit.kind.name, settingsKind);
      expect(habit.priceCents, isNull);
      expect(habit.unitPriceCents, isNull);

      final plans = await _rows(database, 'SELECT habit_id FROM plans');
      expect(plans, hasLength(planCount));
      expect(plans.map((p) => p['habit_id']), everyElement(1));
      expect((await _history(database, 1)).plans, hasLength(planCount));

      expect(await _rows(database, 'SELECT id FROM habits'), hasLength(1));
      final logs = await _rows(database, 'SELECT habit_id FROM habit_logs');
      expect(logCount, 44);
      expect(logs, hasLength(logCount));
      expect(logs.map((l) => l['habit_id']), everyElement(1));
    });

    test('logs of every kind join habit 1', () async {
      final database = _open(
        (raw) => _createV7Schema(
          raw,
          settingsValues: "(1, 'vaping', NULL, NULL, 'Breathe', 1200, 30)",
          logKinds: ['smoking', 'vaping', 'vaping'],
        ),
      );
      addTearDown(database.close);

      await _expectLatest(database);
      final habits = await _rows(
        database,
        'SELECT id, kind, archived_at FROM habits',
      );
      expect(habits.map((h) => (h['id'], h['kind'], h['archived_at'])), [
        (1, 'vaping', null),
      ]);

      final logs = await _rows(
        database,
        'SELECT habit_id FROM habit_logs ORDER BY logged_at',
      );
      expect(logs.map((l) => l['habit_id']), [1, 1, 1]);

      final [vaping] = await _activeHabits(database);
      expect(vaping.reason, 'Breathe');
      expect(vaping.priceCents, 1200);
      expect(vaping.unitsPerContainer, 30);
      expect(vaping.unitPriceCents, 40.0);
    });

    test('a custom habit keeps its name and unit', () async {
      final database = _open(
        (raw) => _createV7Schema(
          raw,
          settingsValues: "(1, 'custom', 'Gaming', 'hour', NULL, NULL, 20)",
          logKinds: ['custom'],
        ),
      );
      addTearDown(database.close);

      final [habit] = await _activeHabits(database);
      expect(habit.habit, Habit.custom(name: 'Gaming', unit: 'hour'));
      expect(
        (await _rows(database, 'SELECT habit_id FROM habit_logs')).single,
        {'habit_id': 1},
      );
    });

    test('an unfinished setup creates no habit', () async {
      final database = _open(
        (raw) => _createV7Schema(
          raw,
          settingsValues: "(1, 'vaping', NULL, NULL, NULL, NULL, 20)",
          withPlan: false,
        ),
      );
      addTearDown(database.close);

      await _expectLatest(database);
      expect(await _activeHabits(database), isEmpty);
    });
  });

  group('upgrade from v8', () {
    late AppDatabase database;

    setUp(() {
      final dir = Directory.systemTemp.createTempSync('exhale_v8');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('test/fixtures/exhale_v8.sqlite')
          .copySync('${dir.path}/exhale.sqlite');
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      database = AppDatabase(NativeDatabase(file));
      addTearDown(database.close);
    });

    test('ends on v9', () => _expectLatest(database));

    test('keeps settings; wake and bed times start unset', () async {
      final settings = await _settings(database);
      expect(settings.currencySymbol, 'AED');
      expect(settings.wakeMinute, isNull);
      expect(settings.bedMinute, isNull);
    });

    test('keeps the habit and its plan', () async {
      final [habit] = await _activeHabits(database);
      expect(habit.id, 1);
      expect(habit.habit, Habit.smoking);
      expect(habit.priceCents, 1500);

      final [plan] = (await _history(database, 1)).plans;
      expect(plan.startDay, LogicalDay(2026, 10, 20));
      expect(plan.startLimit, 10);
      expect(plan.quitDay, LogicalDay(2026, 12, 1));
    });
  });

  test('a plan without a settings row becomes a smoking habit 1', () async {
    final database = _open(_createV7Schema);
    addTearDown(database.close);

    await _expectLatest(database);
    final [habit] = await _activeHabits(database);
    expect(habit.habit, Habit.smoking);
    expect(habit.unitsPerContainer, 20);
  });

  test('logs without a plan keep a stopped habit, so setup runs', () async {
    final database = _open(
      (raw) => _createV7Schema(
        raw,
        settingsValues: "(1, 'vaping', NULL, NULL, NULL, NULL, 20)",
        logKinds: ['vaping'],
        withPlan: false,
      ),
    );
    addTearDown(database.close);

    await _expectLatest(database);
    expect(await _activeHabits(database), isEmpty);
    expect(await _rows(database, 'SELECT habit_id FROM habit_logs'), [
      {'habit_id': 1},
    ]);
  });

  test('a fresh install creates v9 with no habit', () async {
    final database = _open((_) {});
    addTearDown(database.close);

    await _expectLatest(database);
    expect(await _activeHabits(database), isEmpty);
  });
}

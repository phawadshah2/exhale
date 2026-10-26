import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:exhale/core/data/local/database/tables/habit_logs_table.dart';
import 'package:exhale/core/data/local/database/tables/habits_table.dart';
import 'package:exhale/core/data/local/database/tables/plans_table.dart';
import 'package:exhale/core/data/local/database/tables/settings_table.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Habits, Plans, HabitLogs, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? _createConnection());

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) => transaction(() async {
      if (from < 7) {
        // v7 renamed smoke_logs to habit_logs.
        await migrator.renameTable(habitLogs, 'smoke_logs');
        await customStatement('DROP INDEX IF EXISTS idx_smoke_logs_logged_at');
        await migrator.create(idxHabitLogsLoggedAt);
      }
      if (from < 8) await _moveHabitsToTheirOwnTable(migrator, from);
      // drift writes the version only after the migration returns; writing it
      // here too keeps a kill in between from rerunning a finished step.
      await customStatement('PRAGMA user_version = $to');
    }),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// v8 moves the habit, reason and price from settings into `habits` and
  /// keys plans and logs by habit. Rebuilding plans and settings also covers
  /// the older steps: quit dates (v3), trigger settings (v4), dropping
  /// glass_effects (v5) and the cigarette-only column names (v7).
  Future<void> _moveHabitsToTheirOwnTable(Migrator migrator, int from) async {
    await migrator.createTable(habits);

    String fromV6(String column) => from < 6 ? 'NULL' : 's.$column';
    final price = from < 7 ? 's.pack_price_cents' : 's.price_cents';
    final units = from < 7 ? 's.cigarettes_per_pack' : 's.units_per_container';
    const now = "CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)";

    // Only an install with data gets habit 1; without a plan it is stopped,
    // so setup runs again and the logs are kept.
    await customStatement('''
      INSERT INTO habits (id, kind, custom_name, custom_unit, reason,
        price_cents, units_per_container, created_at, archived_at)
      SELECT 1,
        COALESCE(${fromV6('habit_kind')}, 'smoking'),
        ${fromV6('custom_habit_name')},
        ${fromV6('custom_habit_unit')},
        ${fromV6('reason')},
        $price,
        COALESCE($units, 20),
        COALESCE((SELECT MIN(created_at) FROM plans), $now),
        CASE WHEN EXISTS (SELECT 1 FROM plans) THEN NULL ELSE $now END
      FROM (SELECT 1) LEFT JOIN settings s ON s.id = 1
      WHERE EXISTS (SELECT 1 FROM plans) OR EXISTS (SELECT 1 FROM habit_logs)
    ''');

    await migrator.alterTable(
      TableMigration(
        plans,
        columnTransformer: {
          plans.habitId: const Constant(1),
          if (from < 3)
            // v3 replaced "-1 every step_days down to target_limit" with a
            // quit date: the day the old schedule reached its target.
            plans.quitDay: const CustomExpression<String>(
              "date(start_day, '+' || "
              "((start_limit - target_limit) * step_days) || ' days')",
            ),
        },
      ),
    );
    await migrator.alterTable(
      TableMigration(
        habitLogs,
        // v7 stamped every log with its column default, so its habit_kind
        // says nothing; all logs belong to habit 1.
        columnTransformer: {habitLogs.habitId: const Constant(1)},
      ),
    );
    await migrator.create(idxHabitLogsHabitIdLoggedAt);
    await migrator.alterTable(
      TableMigration(
        settings,
        newColumns: [
          settings.logHintSeen,
          if (from < 4) ...[
            settings.askForTrigger,
            settings.triggerPromptIntroSeen,
          ],
        ],
      ),
    );
  }

  static QueryExecutor _createConnection() {
    return driftDatabase(
      name: 'exhale',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}

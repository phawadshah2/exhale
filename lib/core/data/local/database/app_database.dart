import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:exhale/core/data/local/database/tables/habit_logs_table.dart';
import 'package:exhale/core/data/local/database/tables/plans_table.dart';
import 'package:exhale/core/data/local/database/tables/settings_table.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Plans, HabitLogs, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? _createConnection());

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      // v2 added settings.glass_effects; v5 drops it again, so it is
      // skipped here.
      if (from < 3) {
        // v3 replaces "-1 every step_days down to target_limit" with a quit
        // date: the day the old schedule reached its target.
        await migrator.alterTable(
          TableMigration(
            plans,
            columnTransformer: {
              plans.quitDay: const CustomExpression<String>(
                "date(start_day, '+' || "
                "((start_limit - target_limit) * step_days) || ' days')",
              ),
            },
            newColumns: [plans.quitDay],
          ),
        );
      }
      if (from < 4) {
        await migrator.addColumn(settings, settings.askForTrigger);
        await migrator.addColumn(settings, settings.triggerPromptIntroSeen);
      }
      if (from < 5) {
        // v5 drops glass_effects: glass follows Reduce Transparency instead.
        // Rebuilding the table also brings it to v7: habit columns and the
        // renamed price columns.
        await migrator.alterTable(
          TableMigration(
            settings,
            columnTransformer: _renamedPriceColumns.map(
              (column, oldName) => MapEntry(column, CustomExpression(oldName)),
            ),
            newColumns: _habitColumns,
          ),
        );
      } else {
        if (from < 6) {
          for (final column in _habitColumns) {
            await migrator.addColumn(settings, column);
          }
        }
        if (from < 7) {
          for (final MapEntry(key: column, value: oldName)
              in _renamedPriceColumns.entries) {
            await migrator.renameColumn(settings, oldName, column);
          }
        }
      }
      if (from < 7) {
        // v7 renames smoke_logs to habit_logs and records the habit per log.
        await migrator.renameTable(habitLogs, 'smoke_logs');
        await customStatement('DROP INDEX IF EXISTS idx_smoke_logs_logged_at');
        await migrator.create(idxHabitLogsLoggedAt);
        await migrator.addColumn(habitLogs, habitLogs.habitKind);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Added in v6; existing rows become the smoking habit.
  List<GeneratedColumn<Object>> get _habitColumns => [
    settings.habitKind,
    settings.customHabitName,
    settings.customHabitUnit,
    settings.reason,
  ];

  /// Renamed in v7 from their cigarette-only names.
  Map<GeneratedColumn<Object>, String> get _renamedPriceColumns => {
    settings.priceCents: 'pack_price_cents',
    settings.unitsPerContainer: 'cigarettes_per_pack',
  };

  static QueryExecutor _createConnection() {
    return driftDatabase(
      name: 'exhale',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}

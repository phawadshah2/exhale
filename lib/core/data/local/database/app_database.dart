import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:exhale/core/data/local/database/tables/plans_table.dart';
import 'package:exhale/core/data/local/database/tables/settings_table.dart';
import 'package:exhale/core/data/local/database/tables/smoke_logs_table.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Plans, SmokeLogs, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? _createConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(settings, settings.glassEffects);
      }
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
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  static QueryExecutor _createConnection() {
    return driftDatabase(
      name: 'exhale',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}

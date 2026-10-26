import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';

AppDatabase createTestDatabase() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

/// Inserts an active habit for plans and logs to point at; returns its id.
Future<int> insertTestHabit(
  AppDatabase database, {
  HabitKind kind = HabitKind.vaping,
  DateTime? createdAt,
}) => database
    .into(database.habits)
    .insert(
      HabitsCompanion.insert(
        kind: kind.name,
        createdAt: Value(createdAt ?? DateTime(2026, 10)),
      ),
    );

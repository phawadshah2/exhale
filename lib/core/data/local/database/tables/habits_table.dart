import 'package:drift/drift.dart';

@DataClassName('HabitRow')
class Habits extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// HabitKind.name.
  TextColumn get kind => text()();

  /// Name and unit of a custom habit.
  TextColumn get customName => text().named('custom_name').nullable()();
  TextColumn get customUnit => text().named('custom_unit').nullable()();
  TextColumn get reason => text().nullable()();

  /// Per container when the habit has one, else per unit.
  IntColumn get priceCents => integer().named('price_cents').nullable()();
  IntColumn get unitsPerContainer =>
      integer().named('units_per_container').withDefault(const Constant(20))();
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  /// Set when the user stops tracking the habit; its data is kept.
  DateTimeColumn get archivedAt => dateTime().named('archived_at').nullable()();

  /// Set once the user has seen the quit date reached.
  DateTimeColumn get quitAcknowledgedAt =>
      dateTime().named('quit_acknowledged_at').nullable()();
}

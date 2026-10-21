import 'package:drift/drift.dart';

/// Single-row table; the row always has [id] 1.
@DataClassName('SettingsRow')
class Settings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get userName => text().named('user_name').nullable()();
  IntColumn get dayResetHour =>
      integer().named('day_reset_hour').withDefault(const Constant(4))();
  TextColumn get themePreference =>
      text().named('theme_preference').withDefault(const Constant('system'))();
  IntColumn get accentIndex =>
      integer().named('accent_index').withDefault(const Constant(0))();
  TextColumn get appIcon =>
      text().named('app_icon').withDefault(const Constant('breath'))();

  /// Per container when the habit has one, else per unit.
  IntColumn get priceCents => integer().named('price_cents').nullable()();
  IntColumn get unitsPerContainer =>
      integer().named('units_per_container').withDefault(const Constant(20))();
  BoolColumn get askForTrigger =>
      boolean().named('ask_for_trigger').withDefault(const Constant(true))();
  BoolColumn get triggerPromptIntroSeen => boolean()
      .named('trigger_prompt_intro_seen')
      .withDefault(const Constant(false))();

  /// HabitKind.name; rows from before v6 were smoking.
  TextColumn get habitKind =>
      text().named('habit_kind').withDefault(const Constant('smoking'))();
  TextColumn get customHabitName =>
      text().named('custom_habit_name').nullable()();
  TextColumn get customHabitUnit =>
      text().named('custom_habit_unit').nullable()();
  TextColumn get reason => text().nullable()();
  TextColumn get currencySymbol =>
      text().named('currency_symbol').withDefault(const Constant(r'$'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

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
  BoolColumn get askForTrigger =>
      boolean().named('ask_for_trigger').withDefault(const Constant(true))();
  BoolColumn get triggerPromptIntroSeen => boolean()
      .named('trigger_prompt_intro_seen')
      .withDefault(const Constant(false))();

  /// True once the one-time "Hold + for more" hint was shown.
  BoolColumn get logHintSeen =>
      boolean().named('log_hint_seen').withDefault(const Constant(false))();

  TextColumn get currencySymbol =>
      text().named('currency_symbol').withDefault(const Constant(r'$'))();

  /// Wake and bed times in minutes after midnight; null until set.
  IntColumn get wakeMinute => integer().named('wake_minute').nullable()();
  IntColumn get bedMinute => integer().named('bed_minute').nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

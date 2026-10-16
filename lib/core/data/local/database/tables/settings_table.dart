import 'package:drift/drift.dart';

/// Single-row table; the row always has [id] 1.
@DataClassName('SettingsRow')
class Settings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get userName => text().named('user_name').nullable()();
  IntColumn get dayResetHour =>
      integer().named('day_reset_hour').withDefault(const Constant(4))();
  TextColumn get themePreference =>
      text().named('theme_preference').withDefault(const Constant('dark'))();
  IntColumn get accentIndex =>
      integer().named('accent_index').withDefault(const Constant(0))();
  TextColumn get appIcon =>
      text().named('app_icon').withDefault(const Constant('breath'))();
  IntColumn get packPriceCents =>
      integer().named('pack_price_cents').nullable()();
  IntColumn get cigarettesPerPack =>
      integer().named('cigarettes_per_pack').withDefault(const Constant(20))();
  TextColumn get currencySymbol =>
      text().named('currency_symbol').withDefault(const Constant(r'$'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

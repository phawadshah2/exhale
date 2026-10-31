import 'package:drift/drift.dart';
import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/features/settings/domain/entities/app_icon_choice.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/entities/theme_preference.dart';

extension SettingsRowMapper on SettingsRow {
  AppSettings toEntity() => AppSettings(
    userName: userName,
    dayResetHour: dayResetHour,
    themePreference:
        ThemePreference.values.asNameMap()[themePreference] ??
        ThemePreference.system,
    accentIndex: accentIndex,
    appIcon: AppIconChoice.values.asNameMap()[appIcon] ?? AppIconChoice.breath,
    currencySymbol: currencySymbol,
    askForTrigger: askForTrigger,
    triggerPromptIntroSeen: triggerPromptIntroSeen,
    logHintSeen: logHintSeen,
    wakeMinute: wakeMinute,
    bedMinute: bedMinute,
  );
}

extension AppSettingsMapper on AppSettings {
  SettingsCompanion toCompanion() => SettingsCompanion(
    id: const Value(1),
    userName: Value(userName),
    dayResetHour: Value(dayResetHour),
    themePreference: Value(themePreference.name),
    accentIndex: Value(accentIndex),
    appIcon: Value(appIcon.name),
    currencySymbol: Value(currencySymbol),
    askForTrigger: Value(askForTrigger),
    triggerPromptIntroSeen: Value(triggerPromptIntroSeen),
    logHintSeen: Value(logHintSeen),
    wakeMinute: Value(wakeMinute),
    bedMinute: Value(bedMinute),
  );
}

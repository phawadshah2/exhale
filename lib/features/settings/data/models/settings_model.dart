import 'package:drift/drift.dart';
import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
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
    priceCents: priceCents,
    unitsPerContainer: unitsPerContainer,
    currencySymbol: currencySymbol,
    askForTrigger: askForTrigger,
    triggerPromptIntroSeen: triggerPromptIntroSeen,
    habitKind: HabitKind.values.asNameMap()[habitKind] ?? HabitKind.smoking,
    customHabitName: customHabitName,
    customHabitUnit: customHabitUnit,
    reason: reason,
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
    priceCents: Value(priceCents),
    unitsPerContainer: Value(unitsPerContainer),
    currencySymbol: Value(currencySymbol),
    askForTrigger: Value(askForTrigger),
    triggerPromptIntroSeen: Value(triggerPromptIntroSeen),
    habitKind: Value(habitKind.name),
    customHabitName: Value(customHabitName),
    customHabitUnit: Value(customHabitUnit),
    reason: Value(reason),
  );
}

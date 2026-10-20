import 'package:exhale/core/domain/time/day_boundary.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/settings/domain/entities/app_icon_choice.dart';
import 'package:exhale/features/settings/domain/entities/theme_preference.dart';
import 'package:meta/meta.dart';

@immutable
class AppSettings {
  const AppSettings({
    this.userName,
    this.dayResetHour = DayBoundary.defaultResetHour,
    this.themePreference = ThemePreference.system,
    this.accentIndex = 0,
    this.appIcon = AppIconChoice.breath,
    this.priceCents,
    this.unitsPerContainer = defaultUnitsPerContainer,
    this.currencySymbol = defaultCurrencySymbol,
    this.askForTrigger = true,
    this.triggerPromptIntroSeen = false,
    this.habitKind = HabitKind.smoking,
    this.customHabitName,
    this.customHabitUnit,
    this.reason,
  });

  static const int defaultUnitsPerContainer = 20;
  static const String defaultCurrencySymbol = r'$';

  final String? userName;
  final int dayResetHour;
  final ThemePreference themePreference;
  final int accentIndex;
  final AppIconChoice appIcon;
  final int? priceCents;
  final int unitsPerContainer;
  final String currencySymbol;

  /// Show the trigger picker before each log is saved.
  final bool askForTrigger;

  /// The first log offers to stop asking; true once that offer was shown.
  final bool triggerPromptIntroSeen;

  /// The habit being cut down. Installs from before habits were smoking.
  final HabitKind habitKind;

  /// Name and unit of a [HabitKind.custom] habit.
  final String? customHabitName;
  final String? customHabitUnit;

  /// The user's own words for why they are cutting down.
  final String? reason;

  Habit get habit => habitKind == HabitKind.custom
      ? Habit.custom(name: customHabitName ?? '', unit: customHabitUnit ?? '')
      : Habit.preset(habitKind);

  DayBoundary get dayBoundary => DayBoundary(resetHour: dayResetHour);

  /// [priceCents] is per container when the habit has one, else per unit.
  /// Null when no price is set or the habit has no cost.
  double? get unitPriceCents {
    final price = priceCents;
    if (price == null || !habit.tracksCost) return null;
    return habit.hasContainer ? price / unitsPerContainer : price.toDouble();
  }

  AppSettings copyWith({
    String? Function()? userName,
    int? dayResetHour,
    ThemePreference? themePreference,
    int? accentIndex,
    AppIconChoice? appIcon,
    int? Function()? priceCents,
    int? unitsPerContainer,
    String? currencySymbol,
    bool? askForTrigger,
    bool? triggerPromptIntroSeen,
    HabitKind? habitKind,
    String? Function()? customHabitName,
    String? Function()? customHabitUnit,
    String? Function()? reason,
  }) => AppSettings(
    userName: userName != null ? userName() : this.userName,
    dayResetHour: dayResetHour ?? this.dayResetHour,
    themePreference: themePreference ?? this.themePreference,
    accentIndex: accentIndex ?? this.accentIndex,
    appIcon: appIcon ?? this.appIcon,
    priceCents: priceCents != null ? priceCents() : this.priceCents,
    unitsPerContainer: unitsPerContainer ?? this.unitsPerContainer,
    currencySymbol: currencySymbol ?? this.currencySymbol,
    askForTrigger: askForTrigger ?? this.askForTrigger,
    triggerPromptIntroSeen:
        triggerPromptIntroSeen ?? this.triggerPromptIntroSeen,
    habitKind: habitKind ?? this.habitKind,
    customHabitName: customHabitName != null
        ? customHabitName()
        : this.customHabitName,
    customHabitUnit: customHabitUnit != null
        ? customHabitUnit()
        : this.customHabitUnit,
    reason: reason != null ? reason() : this.reason,
  );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.userName == userName &&
      other.dayResetHour == dayResetHour &&
      other.themePreference == themePreference &&
      other.accentIndex == accentIndex &&
      other.appIcon == appIcon &&
      other.priceCents == priceCents &&
      other.unitsPerContainer == unitsPerContainer &&
      other.currencySymbol == currencySymbol &&
      other.askForTrigger == askForTrigger &&
      other.triggerPromptIntroSeen == triggerPromptIntroSeen &&
      other.habitKind == habitKind &&
      other.customHabitName == customHabitName &&
      other.customHabitUnit == customHabitUnit &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(
    userName,
    dayResetHour,
    themePreference,
    accentIndex,
    appIcon,
    priceCents,
    unitsPerContainer,
    currencySymbol,
    askForTrigger,
    triggerPromptIntroSeen,
    habitKind,
    customHabitName,
    customHabitUnit,
    reason,
  );
}

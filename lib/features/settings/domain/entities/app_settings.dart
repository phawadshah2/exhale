import 'package:exhale/core/domain/time/day_boundary.dart';
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
    this.currencySymbol = defaultCurrencySymbol,
    this.askForTrigger = true,
    this.triggerPromptIntroSeen = false,
    this.logHintSeen = false,
  });

  static const String defaultCurrencySymbol = r'$';

  final String? userName;
  final int dayResetHour;
  final ThemePreference themePreference;
  final int accentIndex;
  final AppIconChoice appIcon;
  final String currencySymbol;

  /// Show the trigger picker before each log is saved.
  final bool askForTrigger;

  /// The first log offers to stop asking; true once that offer was shown.
  final bool triggerPromptIntroSeen;

  /// True once the one-time "Hold + for more" hint was shown.
  final bool logHintSeen;

  DayBoundary get dayBoundary => DayBoundary(resetHour: dayResetHour);

  AppSettings copyWith({
    String? Function()? userName,
    int? dayResetHour,
    ThemePreference? themePreference,
    int? accentIndex,
    AppIconChoice? appIcon,
    String? currencySymbol,
    bool? askForTrigger,
    bool? triggerPromptIntroSeen,
    bool? logHintSeen,
  }) => AppSettings(
    userName: userName != null ? userName() : this.userName,
    dayResetHour: dayResetHour ?? this.dayResetHour,
    themePreference: themePreference ?? this.themePreference,
    accentIndex: accentIndex ?? this.accentIndex,
    appIcon: appIcon ?? this.appIcon,
    currencySymbol: currencySymbol ?? this.currencySymbol,
    askForTrigger: askForTrigger ?? this.askForTrigger,
    triggerPromptIntroSeen:
        triggerPromptIntroSeen ?? this.triggerPromptIntroSeen,
    logHintSeen: logHintSeen ?? this.logHintSeen,
  );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.userName == userName &&
      other.dayResetHour == dayResetHour &&
      other.themePreference == themePreference &&
      other.accentIndex == accentIndex &&
      other.appIcon == appIcon &&
      other.currencySymbol == currencySymbol &&
      other.askForTrigger == askForTrigger &&
      other.triggerPromptIntroSeen == triggerPromptIntroSeen &&
      other.logHintSeen == logHintSeen;

  @override
  int get hashCode => Object.hash(
    userName,
    dayResetHour,
    themePreference,
    accentIndex,
    appIcon,
    currencySymbol,
    askForTrigger,
    triggerPromptIntroSeen,
    logHintSeen,
  );
}

import 'package:exhale/core/domain/time/day_boundary.dart';
import 'package:exhale/features/settings/domain/entities/app_icon_choice.dart';
import 'package:exhale/features/settings/domain/entities/day_window.dart';
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
    this.wakeMinute,
    this.bedMinute,
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

  /// Wake and bed times in minutes after midnight; null until set.
  final int? wakeMinute;
  final int? bedMinute;

  DayBoundary get dayBoundary => DayBoundary(resetHour: dayResetHour);

  /// Null unless both times are set.
  DayWindow? get dayWindow => switch ((wakeMinute, bedMinute)) {
    (final int wake, final int bed) => DayWindow(
      wakeMinute: wake,
      bedMinute: bed,
    ),
    _ => null,
  };

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
    int? Function()? wakeMinute,
    int? Function()? bedMinute,
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
    wakeMinute: wakeMinute != null ? wakeMinute() : this.wakeMinute,
    bedMinute: bedMinute != null ? bedMinute() : this.bedMinute,
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
      other.logHintSeen == logHintSeen &&
      other.wakeMinute == wakeMinute &&
      other.bedMinute == bedMinute;

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
    wakeMinute,
    bedMinute,
  );
}

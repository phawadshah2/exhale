import 'package:exhale/core/domain/time/day_boundary.dart';
import 'package:exhale/core/theme/app_palette.dart';
import 'package:exhale/features/settings/domain/entities/app_icon_choice.dart';
import 'package:exhale/features/settings/domain/entities/day_window.dart';
import 'package:exhale/features/settings/domain/entities/theme_preference.dart';
import 'package:meta/meta.dart';

@immutable
class AppSettings {
  const AppSettings({
    this.userName,
    this.dayResetHour = DayBoundary.defaultResetHour,
    this.themePreference = ThemePreference.light,
    this.accentIndex = AppPalette.defaultAccentIndex,
    this.appIcon = AppIconChoice.breath,
    this.currencySymbol = defaultCurrencySymbol,
    this.askForTrigger = true,
    this.triggerPromptIntroSeen = false,
    this.logHintSeen = false,
    this.wakeMinute,
    this.bedMinute,
    this.accessState,
    this.accessPlan,
    this.accessUntil,
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

  /// The last access the App Store reported ('entitled', 'lapsed' or
  /// 'neverPaid'), its plan's name and end date; null until it first answers.
  final String? accessState;
  final String? accessPlan;
  final DateTime? accessUntil;

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
    String? Function()? accessState,
    String? Function()? accessPlan,
    DateTime? Function()? accessUntil,
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
    accessState: accessState != null ? accessState() : this.accessState,
    accessPlan: accessPlan != null ? accessPlan() : this.accessPlan,
    accessUntil: accessUntil != null ? accessUntil() : this.accessUntil,
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
      other.bedMinute == bedMinute &&
      other.accessState == accessState &&
      other.accessPlan == accessPlan &&
      other.accessUntil == accessUntil;

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
    accessState,
    accessPlan,
    accessUntil,
  );
}

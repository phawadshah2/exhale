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
    this.packPriceCents,
    this.cigarettesPerPack = defaultCigarettesPerPack,
    this.currencySymbol = defaultCurrencySymbol,
    this.glassEffects = true,
  });

  static const int defaultCigarettesPerPack = 20;
  static const String defaultCurrencySymbol = r'$';

  final String? userName;
  final int dayResetHour;
  final ThemePreference themePreference;
  final int accentIndex;
  final AppIconChoice appIcon;
  final int? packPriceCents;
  final int cigarettesPerPack;
  final String currencySymbol;

  /// Translucent blurred surfaces (tab bar, sheets, status bar).
  final bool glassEffects;

  DayBoundary get dayBoundary => DayBoundary(resetHour: dayResetHour);

  /// Price of one cigarette in cents, or null when no pack price is set.
  double? get cigarettePriceCents =>
      packPriceCents == null ? null : packPriceCents! / cigarettesPerPack;

  AppSettings copyWith({
    String? Function()? userName,
    int? dayResetHour,
    ThemePreference? themePreference,
    int? accentIndex,
    AppIconChoice? appIcon,
    int? Function()? packPriceCents,
    int? cigarettesPerPack,
    String? currencySymbol,
    bool? glassEffects,
  }) => AppSettings(
    userName: userName != null ? userName() : this.userName,
    dayResetHour: dayResetHour ?? this.dayResetHour,
    themePreference: themePreference ?? this.themePreference,
    accentIndex: accentIndex ?? this.accentIndex,
    appIcon: appIcon ?? this.appIcon,
    packPriceCents: packPriceCents != null
        ? packPriceCents()
        : this.packPriceCents,
    cigarettesPerPack: cigarettesPerPack ?? this.cigarettesPerPack,
    currencySymbol: currencySymbol ?? this.currencySymbol,
    glassEffects: glassEffects ?? this.glassEffects,
  );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.userName == userName &&
      other.dayResetHour == dayResetHour &&
      other.themePreference == themePreference &&
      other.accentIndex == accentIndex &&
      other.appIcon == appIcon &&
      other.packPriceCents == packPriceCents &&
      other.cigarettesPerPack == cigarettesPerPack &&
      other.currencySymbol == currencySymbol &&
      other.glassEffects == glassEffects;

  @override
  int get hashCode => Object.hash(
    userName,
    dayResetHour,
    themePreference,
    accentIndex,
    appIcon,
    packPriceCents,
    cigarettesPerPack,
    currencySymbol,
    glassEffects,
  );
}

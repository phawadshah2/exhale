import 'package:exhale/core/theme/app_palette.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/entities/day_window.dart';

abstract final class SettingsValidation {
  static const int maxNameLength = 40;

  static String? validate(AppSettings settings) {
    if (settings.dayResetHour < 0 || settings.dayResetHour > 23) {
      return 'Day reset hour must be between 0 and 23.';
    }
    if ((settings.userName?.length ?? 0) > maxNameLength) {
      return 'Name must be $maxNameLength characters or fewer.';
    }
    if (settings.accentIndex < 0 ||
        settings.accentIndex >= AppPalette.accents.length) {
      return 'Unknown accent colour.';
    }
    for (final minute in [settings.wakeMinute, settings.bedMinute]) {
      if (minute != null && (minute < 0 || minute >= DayWindow.minutesPerDay)) {
        return 'Times must be within the day.';
      }
    }
    if (settings.dayWindow case final window? when !window.isValid) {
      return 'Your day must be at least 4 hours.';
    }
    return null;
  }
}

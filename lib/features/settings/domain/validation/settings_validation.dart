import 'package:exhale/core/theme/app_palette.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';

abstract final class SettingsValidation {
  static const int maxNameLength = 40;
  static const int maxUnitsPerContainer = 100;
  static const int maxPriceCents = 100000;

  static String? validate(AppSettings settings) {
    if (settings.dayResetHour < 0 || settings.dayResetHour > 23) {
      return 'Day reset hour must be between 0 and 23.';
    }
    if ((settings.userName?.length ?? 0) > maxNameLength) {
      return 'Name must be $maxNameLength characters or fewer.';
    }
    if (settings.unitsPerContainer < 1 ||
        settings.unitsPerContainer > maxUnitsPerContainer) {
      return 'Units per container must be between 1 and '
          '$maxUnitsPerContainer.';
    }
    final price = settings.priceCents;
    if (price != null && (price < 0 || price > maxPriceCents)) {
      return 'Price is out of range.';
    }
    if (settings.accentIndex < 0 ||
        settings.accentIndex >= AppPalette.accents.length) {
      return 'Unknown accent colour.';
    }
    return null;
  }
}

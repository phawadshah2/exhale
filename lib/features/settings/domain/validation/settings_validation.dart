import 'package:exhale/core/theme/app_palette.dart';
import 'package:exhale/features/settings/domain/entities/app_settings.dart';

abstract final class SettingsValidation {
  static const int maxNameLength = 40;
  static const int maxCigarettesPerPack = 100;
  static const int maxPackPriceCents = 100000;

  static String? validate(AppSettings settings) {
    if (settings.dayResetHour < 0 || settings.dayResetHour > 23) {
      return 'Day reset hour must be between 0 and 23.';
    }
    if ((settings.userName?.length ?? 0) > maxNameLength) {
      return 'Name must be $maxNameLength characters or fewer.';
    }
    if (settings.cigarettesPerPack < 1 ||
        settings.cigarettesPerPack > maxCigarettesPerPack) {
      return 'Cigarettes per pack must be between 1 and '
          '$maxCigarettesPerPack.';
    }
    final price = settings.packPriceCents;
    if (price != null && (price < 0 || price > maxPackPriceCents)) {
      return 'Pack price is out of range.';
    }
    if (settings.accentIndex < 0 ||
        settings.accentIndex >= AppPalette.accents.length) {
      return 'Unknown accent colour.';
    }
    return null;
  }
}

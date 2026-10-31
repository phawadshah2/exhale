import 'package:exhale/features/settings/domain/entities/app_settings.dart';
import 'package:exhale/features/settings/domain/validation/settings_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String? validate(AppSettings settings) =>
      SettingsValidation.validate(settings);

  test('defaults are valid, with no day set', () {
    expect(validate(const AppSettings()), isNull);
  });

  test('a day of 4 hours or more is valid', () {
    expect(validate(const AppSettings(wakeMinute: 420, bedMinute: 60)), isNull);
    expect(
      validate(const AppSettings(wakeMinute: 480, bedMinute: 720)),
      isNull,
    );
  });

  test('a time outside the day is rejected', () {
    for (final settings in const [
      AppSettings(wakeMinute: -1, bedMinute: 1410),
      AppSettings(wakeMinute: 450, bedMinute: 1440),
      AppSettings(wakeMinute: 1440),
      AppSettings(bedMinute: -5),
    ]) {
      expect(validate(settings), 'Times must be within the day.');
    }
  });

  test('a day under 4 hours is rejected', () {
    expect(
      validate(const AppSettings(wakeMinute: 1380, bedMinute: 120)),
      'Your day must be at least 4 hours.',
    );
    expect(
      validate(const AppSettings(wakeMinute: 450, bedMinute: 450)),
      'Your day must be at least 4 hours.',
    );
  });

  test('one time without the other is not a window yet', () {
    expect(validate(const AppSettings(wakeMinute: 450)), isNull);
    expect(const AppSettings(wakeMinute: 450).dayWindow, isNull);
  });
}

/// Settings' strings. The subscription's live in `PaywallCopy`.
abstract final class SettingsCopy {
  static const title = 'Settings';

  static const editPlan = 'Edit plan';
  static const price = 'Price';
  static const notSet = 'Not set';
  static const changeHabit = 'Change habit';

  static const yourDay = 'Your day';
  static const awake = 'Awake';

  static const logging = 'Logging';
  static const askTrigger = 'Ask what set it off';

  static const lockScreen = 'Lock Screen';
  static const lockScreenCountdown = 'Countdown on Lock Screen';

  static const appearance = 'Appearance';
  static const theme = 'Theme';
  static const accent = 'Accent';
  static const themeLight = 'Light';
  static const themeDark = 'Dark';
  static const themeSystem = 'System';

  static const about = 'About';
  static const rate = 'Rate Exhale';
  static const feedback = 'Send feedback';
  static const privacy = 'Privacy policy';
  static const terms = 'Terms of use';
  static const addressCopied =
      'Address copied. No Mail account on this iPhone.';
  static String version(String version) => 'Exhale $version';
}

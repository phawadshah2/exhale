import 'package:meta/meta.dart';

/// The user's waking hours, as minutes after midnight. Bed may be after
/// midnight, so it can be earlier than wake.
@immutable
class DayWindow {
  const DayWindow({required this.wakeMinute, required this.bedMinute});

  /// 7:30.
  static const int defaultWake = 450;

  /// 23:30.
  static const int defaultBed = 1410;

  static const int minAwakeMinutes = 240;
  static const int minutesPerDay = 1440;

  final int wakeMinute;
  final int bedMinute;

  /// Time from wake to bed, wrapping past midnight; 0 when they are equal.
  int get awakeMinutes => (bedMinute - wakeMinute) % minutesPerDay;

  bool get isValid => awakeMinutes >= minAwakeMinutes;

  @override
  bool operator ==(Object other) =>
      other is DayWindow &&
      other.wakeMinute == wakeMinute &&
      other.bedMinute == bedMinute;

  @override
  int get hashCode => Object.hash(wakeMinute, bedMinute);
}

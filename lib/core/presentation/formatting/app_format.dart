import 'package:exhale/core/domain/time/logical_day.dart';

abstract final class AppFormat {
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', //
    'Friday', 'Saturday', 'Sunday',
  ];

  /// Oct 16
  static String monthDay(LogicalDay day) =>
      '${_months[day.month - 1]} ${day.day}';

  /// 17 Dec 2026
  static String fullDate(LogicalDay day) =>
      '${day.day} ${_months[day.month - 1]} ${day.year}';

  /// Wednesday, Oct 18
  static String weekdayDate(LogicalDay day) =>
      '${_weekdays[day.weekday - 1]}, ${monthDay(day)}';

  /// Today, Oct 16 / Tomorrow, Oct 17 / Wednesday, Oct 18
  static String relativeDate(LogicalDay day, {required LogicalDay today}) {
    final offset = day.daysSince(today);
    if (offset == 0) return 'Today, ${monthDay(day)}';
    if (offset == 1) return 'Tomorrow, ${monthDay(day)}';
    if (offset == -1) return 'Yesterday, ${monthDay(day)}';
    return weekdayDate(day);
  }

  /// 3:42 PM
  static String time(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${time.hour < 12 ? 'AM' : 'PM'}';
  }

  /// $14.50, or $183 with [wholeUnits].
  static String money(
    num cents, {
    required String symbol,
    bool wholeUnits = false,
  }) {
    final units = cents / 100;
    return wholeUnits
        ? '$symbol${units.round()}'
        : '$symbol${units.toStringAsFixed(2)}';
  }

  /// Parses user input like "14.50" or "14,5" into cents.
  /// Returns null for blank, malformed or negative input.
  static int? parseCents(String input) {
    final cleaned = input.trim().replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    final value = double.tryParse(cleaned);
    if (value == null || value < 0 || value.isNaN || value.isInfinite) {
      return null;
    }
    return (value * 100).round();
  }

  /// Just now / 12m / 1h 42m / 2d 3h
  static String elapsed(Duration duration) {
    if (duration.inMinutes < 1) return 'Just now';
    if (duration.inHours < 1) return '${duration.inMinutes}m';
    if (duration.inDays < 1) {
      final minutes = duration.inMinutes % 60;
      return minutes == 0
          ? '${duration.inHours}h'
          : '${duration.inHours}h ${minutes}m';
    }
    final hours = duration.inHours % 24;
    return hours == 0 ? '${duration.inDays}d' : '${duration.inDays}d ${hours}h';
  }

  /// One-letter weekday: M T W T F S S
  static String weekdayInitial(LogicalDay day) =>
      _weekdays[day.weekday - 1].substring(0, 1);

  /// Good morning / afternoon / evening.
  static String greeting(DateTime now) {
    if (now.hour >= 4 && now.hour < 12) return 'Good morning';
    if (now.hour >= 12 && now.hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

import 'package:exhale/core/domain/time/day_boundary.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/home/domain/pace_guide.dart';
import 'package:exhale/features/settings/domain/entities/day_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final day = LogicalDay(2026, 10, 29);
  const boundary = DayBoundary();
  const window = DayWindow(wakeMinute: 450, bedMinute: 1410);

  PaceGuide? compute({
    required DateTime now,
    DayWindow window = window,
    DayBoundary boundary = boundary,
    int limit = 8,
    int countToday = 0,
    DateTime? lastLogToday,
  }) => PaceGuide.compute(
    now: now,
    day: day,
    boundary: boundary,
    window: window,
    limit: limit,
    countToday: countToday,
    lastLogToday: lastLogToday,
  );

  test('at wake with no logs, the day is split evenly', () {
    final guide = compute(now: DateTime(2026, 10, 29, 7, 30))!;

    expect(guide.pace, const Duration(hours: 2));
    expect(guide.next, DateTime(2026, 10, 29, 9, 30));
  });

  test('mid-day, the rest of the day is split over what is left', () {
    final guide = compute(
      now: DateTime(2026, 10, 29, 12),
      countToday: 2,
      lastLogToday: DateTime(2026, 10, 29, 11),
    )!;

    expect(guide.pace, const Duration(hours: 2));
    expect(guide.next, DateTime(2026, 10, 29, 13, 5));
  });

  group('never faster than the even rate', () {
    test('a late start keeps the pace of the whole day', () {
      final guide = compute(now: DateTime(2026, 10, 29, 22), limit: 12)!;

      expect(guide.pace, const Duration(minutes: 80));
      expect(guide.next, DateTime(2026, 10, 29, 8, 50));
    });

    test('a late log waits a full gap', () {
      final lastLog = DateTime(2026, 10, 29, 22);
      final guide = compute(
        now: lastLog,
        limit: 12,
        countToday: 1,
        lastLogToday: lastLog,
      )!;

      expect(guide.next, DateTime(2026, 10, 29, 23, 20));
    });
  });

  test('the guide knows when the window ends', () {
    final guide = compute(now: DateTime(2026, 10, 29, 12))!;

    expect(guide.bed, DateTime(2026, 10, 29, 23, 30));
  });

  test('next holds still until the next log; only the pace moves', () {
    final lastLog = DateTime(2026, 10, 29, 20);
    PaceGuide at(DateTime now) =>
        compute(now: now, countToday: 7, lastLogToday: lastLog)!;

    final early = at(DateTime(2026, 10, 29, 20, 1));
    final late = at(DateTime(2026, 10, 29, 21));

    expect(early.next, DateTime(2026, 10, 29, 23, 30));
    expect(late.next, early.next);
    expect(late.pace, const Duration(hours: 2, minutes: 30));
  });

  test('a log from before wake counts from wake', () {
    final guide = compute(
      now: DateTime(2026, 10, 29, 7, 30),
      limit: 9,
      countToday: 1,
      lastLogToday: DateTime(2026, 10, 29, 6),
    )!;

    expect(guide.next, DateTime(2026, 10, 29, 9, 30));
  });

  group('no guide', () {
    test('before wake', () {
      expect(compute(now: DateTime(2026, 10, 29, 7)), isNull);
    });

    test('at bedtime', () {
      expect(compute(now: DateTime(2026, 10, 29, 23, 30)), isNull);
    });

    test('at the limit', () {
      final now = DateTime(2026, 10, 29, 12);
      expect(compute(now: now, countToday: 8), isNull);
    });

    test('over the limit', () {
      final now = DateTime(2026, 10, 29, 12);
      expect(compute(now: now, countToday: 9), isNull);
    });

    test('limit 0', () {
      final now = DateTime(2026, 10, 29, 12);
      expect(compute(now: now, limit: 0), isNull);
    });
  });

  test('a bedtime after midnight falls on the next calendar date', () {
    final guide = compute(
      now: DateTime(2026, 10, 29, 23),
      window: const DayWindow(wakeMinute: 450, bedMinute: 60),
      countToday: 7,
      lastLogToday: DateTime(2026, 10, 29, 22, 30),
    )!;

    expect(guide.pace, const Duration(hours: 2, minutes: 11, seconds: 15));
    expect(guide.next, DateTime(2026, 10, 30, 1));
  });

  test('a bedtime after the reset hour is cut at the reset', () {
    const lateBed = DayWindow(wakeMinute: 450, bedMinute: 300);

    final guide = compute(
      now: DateTime(2026, 10, 30, 3),
      window: lateBed,
      limit: 1,
    )!;
    expect(guide.pace, const Duration(hours: 20, minutes: 30));
    expect(guide.bed, DateTime(2026, 10, 30, 4));

    expect(compute(now: DateTime(2026, 10, 30, 4), window: lateBed), isNull);
  });

  test('a wake before the reset hour starts at the reset', () {
    final guide = compute(
      now: DateTime(2026, 10, 29, 4),
      window: const DayWindow(wakeMinute: 180, bedMinute: 1410),
      limit: 6,
    )!;

    expect(guide.pace, const Duration(hours: 3, minutes: 15));
    expect(guide.next, DateTime(2026, 10, 29, 7, 15));
  });
}

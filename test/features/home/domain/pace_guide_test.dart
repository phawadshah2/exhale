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
    List<DateTime> earlierLogsToday = const [],
  }) => PaceGuide.compute(
    now: now,
    day: day,
    boundary: boundary,
    window: window,
    limit: limit,
    countToday: countToday,
    lastLogToday: lastLogToday,
    earlierLogsToday: earlierLogsToday,
  );

  group('time left on the timer carries over', () {
    // Limit 8 over 16 h: an even gap of 2 h.
    final onTime = DateTime(2026, 10, 29, 9, 30);

    test('a log with 30 min left adds them to the next gap', () {
      final guide = compute(
        now: DateTime(2026, 10, 29, 11),
        countToday: 2,
        earlierLogsToday: [onTime],
        lastLogToday: DateTime(2026, 10, 29, 11),
      )!;

      // 12.5 h over 6 is 125 min, plus the 30 that were left.
      expect(guide.gap, const Duration(minutes: 155));
      expect(guide.next, DateTime(2026, 10, 29, 13, 35));
    });

    test('a log exactly on time carries nothing', () {
      final guide = compute(now: onTime, countToday: 1, lastLogToday: onTime)!;

      expect(guide.next, DateTime(2026, 10, 29, 11, 30));
    });

    test('the first log of the day counts down from wake too', () {
      final at = DateTime(2026, 10, 29, 9);
      final guide = compute(now: at, countToday: 1, lastLogToday: at)!;

      // 30 min were left of the 2 h from wake; 14.5 h over 7 is the new gap.
      expect(
        guide.gap,
        const Duration(hours: 14, minutes: 30) ~/ 7 +
            const Duration(minutes: 30),
      );
    });

    test('waiting past zero earns no credit', () {
      final at = DateTime(2026, 10, 29, 12);
      final guide = compute(
        now: at,
        countToday: 2,
        earlierLogsToday: [onTime],
        lastLogToday: at,
      )!;

      expect(guide.gap, const Duration(hours: 2));
    });

    test('it stacks across several early logs', () {
      final second = DateTime(2026, 10, 29, 11);
      final third = DateTime(2026, 10, 29, 11, 30);
      final guide = compute(
        now: third,
        countToday: 3,
        earlierLogsToday: [onTime, second],
        lastLogToday: third,
      )!;

      // The second log left 13:35 due, so 2:05 was left at 11:30. 12 h over 5
      // is 144 min.
      expect(guide.gap, const Duration(minutes: 144 + 125));
    });

    test('it can run past bed, and the guide still ends at bed', () {
      final first = DateTime(2026, 10, 29, 20);
      final second = DateTime(2026, 10, 29, 21);
      PaceGuide? at(DateTime now) => compute(
        now: now,
        countToday: 2,
        earlierLogsToday: [first],
        lastLogToday: second,
        limit: 3,
      );

      // 5:20 is the even gap at a limit of 3, and 4:20 was left at 21:00.
      expect(at(second)!.gap, const Duration(hours: 9, minutes: 40));
      expect(at(DateTime(2026, 10, 29, 23, 30)), isNull);
    });

    test('a log before wake carries nothing', () {
      final guide = compute(
        now: DateTime(2026, 10, 29, 8),
        countToday: 1,
        lastLogToday: DateTime(2026, 10, 29, 6),
      )!;

      expect(
        guide.next,
        DateTime(2026, 10, 29, 7, 30).add(const Duration(hours: 16) ~/ 7),
      );
    });
  });

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

  group('NextLogTimer', () {
    final lastLog = DateTime(2026, 10, 29, 8);
    PaceGuide guide(DateTime now) =>
        compute(now: now, countToday: 1, lastLogToday: lastLog)!;

    test('the gap runs from the last log to the next one', () {
      final at = guide(DateTime(2026, 10, 29, 9));

      expect(at.gap, at.next.difference(lastLog));
    });

    test('drains from full to empty over the gap', () {
      final full = guide(lastLog);
      expect(NextLogTimer(guide: full, now: lastLog).fraction, 1);

      final half = lastLog.add(full.gap ~/ 2);
      expect(
        NextLogTimer(guide: guide(half), now: half).fraction,
        closeTo(0.5, 0.001),
      );

      final late = full.next.add(const Duration(minutes: 5));
      final past = NextLogTimer(guide: guide(late), now: late);
      expect(past.fraction, 0);
      expect(past.isPast, isTrue);
      expect(past.left, const Duration(minutes: -5));
    });

    test('at zero it counts as past', () {
      final full = guide(lastLog);
      final at = NextLogTimer(guide: guide(full.next), now: full.next);

      expect(at.isPast, isTrue);
    });

    test('the pace shows only when one gap fits before bed', () {
      final early = DateTime(2026, 10, 29, 9);
      final late = DateTime(2026, 10, 29, 23, 29);

      expect(NextLogTimer(guide: guide(early), now: early).showsPace, isTrue);
      expect(NextLogTimer(guide: guide(late), now: late).showsPace, isFalse);
    });

    test('two timers at the same moment are equal', () {
      final now = DateTime(2026, 10, 29, 9);

      expect(
        NextLogTimer(guide: guide(now), now: now),
        NextLogTimer(guide: guide(now), now: now),
      );
    });
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

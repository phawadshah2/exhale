import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/tracking/domain/entities/daily_progress.dart';
import 'package:exhale/features/tracking/domain/entities/limit_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final day = LogicalDay(2026, 10, 16);

  DailyProgress progress(int count, int limit) =>
      DailyProgress(day: day, count: count, limit: limit);

  group('LimitStatus.of', () {
    test('under, at and over the limit', () {
      expect(LimitStatus.of(count: 4, limit: 9), LimitStatus.under);
      expect(LimitStatus.of(count: 9, limit: 9), LimitStatus.at);
      expect(LimitStatus.of(count: 11, limit: 9), LimitStatus.over);
    });

    test('a smoke-free day on a zero limit is under, not at', () {
      expect(LimitStatus.of(count: 0, limit: 0), LimitStatus.under);
      expect(LimitStatus.of(count: 1, limit: 0), LimitStatus.over);
    });
  });

  group('DailyProgress', () {
    test('under the limit', () {
      final p = progress(4, 9);

      expect(p.remaining, 5);
      expect(p.overBy, 0);
      expect(p.status, LimitStatus.under);
      expect(p.usedFraction, closeTo(4 / 9, 1e-9));
    });

    test('at the limit', () {
      final p = progress(9, 9);

      expect(p.remaining, 0);
      expect(p.overBy, 0);
      expect(p.status, LimitStatus.at);
      expect(p.usedFraction, 1);
    });

    test('over the limit', () {
      final p = progress(11, 9);

      expect(p.remaining, 0);
      expect(p.overBy, 2);
      expect(p.status, LimitStatus.over);
      expect(p.usedFraction, 1);
    });

    test('zero limit', () {
      expect(progress(0, 0).usedFraction, 0);
      expect(progress(0, 0).remaining, 0);
      expect(progress(2, 0).usedFraction, 1);
      expect(progress(2, 0).overBy, 2);
    });

    test('rejects negative values', () {
      expect(() => progress(-1, 9), throwsA(isA<AssertionError>()));
      expect(() => progress(1, -1), throwsA(isA<AssertionError>()));
    });

    test('equality is by value', () {
      expect(progress(4, 9), progress(4, 9));
      expect(progress(4, 9).hashCode, progress(4, 9).hashCode);
      expect(progress(4, 9), isNot(progress(5, 9)));
    });
  });
}

import 'dart:math';

import 'package:exhale/features/presence/domain/encouragement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('has 60 distinct lines of at most 40 characters', () {
    expect(encouragementLines, hasLength(60));
    expect(encouragementLines.toSet(), hasLength(60));
    for (final line in encouragementLines) {
      expect(line.length, lessThanOrEqualTo(40), reason: line);
    }
  });

  test('starts with the Home quotes', () {
    expect(encouragementLines.take(7), [
      'Every breath is a fresh decision.',
      'One fewer today is a real win.',
      'Cravings pass. You stay.',
      'Slow is still forward.',
      'Notice the urge, then let it go by.',
      'Each smaller day adds up.',
      'Progress, not perfection.',
    ]);
  });

  test('a pair has two different lines', () {
    final random = Random(1);
    for (var i = 0; i < 1000; i++) {
      final pair = pickLinePair(random);
      expect(pair.counting, isNot(pair.waiting));
      expect(encouragementLines, containsAll([pair.counting, pair.waiting]));
    }
  });

  test("never repeats the last pair's lines", () {
    final random = Random(7);
    var last = pickLinePair(random);
    for (var i = 0; i < 1000; i++) {
      final next = pickLinePair(random, last: last);
      final previous = {last.counting, last.waiting};
      expect(previous, isNot(contains(next.counting)));
      expect(previous, isNot(contains(next.waiting)));
      last = next;
    }
  });

  test('no line says "you can"', () {
    for (final line in encouragementLines) {
      expect(line.toLowerCase(), isNot(contains('you can')), reason: line);
    }
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:exhale/core/domain/time/day_boundary.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/home/domain/pace_guide.dart';
import 'package:exhale/features/settings/domain/entities/day_window.dart';
import 'package:flutter_test/flutter_test.dart';

/// `test/fixtures/pace_cases.json` is shared with the widget extension's
/// XCTest, so the Swift countdown stays in step with [PaceGuide].
void main() {
  final cases = jsonDecode(
    File('test/fixtures/pace_cases.json').readAsStringSync(),
  ) as List<dynamic>;

  Duration seconds(num value) =>
      Duration(microseconds: (value * Duration.microsecondsPerSecond).round());

  test('there are 14 cases', () {
    expect(cases, hasLength(14));
  });

  group('every case matches PaceGuide.compute', () {
    for (final raw in cases) {
      final c = raw as Map<String, dynamic>;
      test(c['name'] as String, () {
        final wake = c['wakeMinute'] as int;
        final logs = [
          for (final log in c['logs'] as List<dynamic>)
            DateTime.parse(log as String),
        ];

        final guide = PaceGuide.compute(
          now: DateTime.parse(c['now'] as String),
          day: LogicalDay.parse(c['day'] as String),
          boundary: DayBoundary(resetHour: c['resetHour'] as int),
          window: DayWindow(
            wakeMinute: wake,
            bedMinute:
                (wake + (c['awakeMinutes'] as int)) % DayWindow.minutesPerDay,
          ),
          limit: c['limit'] as int,
          countToday: c['countToday'] as int,
          lastLogToday: logs.isEmpty ? null : logs.last,
          earlierLogsToday: logs.isEmpty
              ? const []
              : logs.sublist(0, logs.length - 1),
        );

        final expected = c['expect'] as Map<String, dynamic>?;
        if (expected == null) {
          expect(guide, isNull);
          return;
        }
        expect(guide, isNotNull);
        expect(guide!.next, DateTime.parse(expected['next'] as String));
        expect(guide.gap, seconds(expected['gap'] as num));
        expect(guide.pace, seconds(expected['pace'] as num));
        expect(guide.bed, DateTime.parse(expected['bed'] as String));
      });
    }
  });
}

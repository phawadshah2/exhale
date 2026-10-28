import 'package:exhale/core/domain/time/day_boundary.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/tracking/presentation/widgets/log_editor_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final day = LogicalDay(2026, 10, 14);
  const boundary = DayBoundary();

  test('a time after the reset hour stays on the same date', () {
    expect(
      instantOnLogicalDay(day, const TimeOfDay(hour: 12, minute: 0), boundary),
      DateTime(2026, 10, 14, 12),
    );
    expect(
      instantOnLogicalDay(day, const TimeOfDay(hour: 4, minute: 0), boundary),
      DateTime(2026, 10, 14, 4),
    );
  });

  test('a time before the reset hour is the next calendar date', () {
    final at = instantOnLogicalDay(
      day,
      const TimeOfDay(hour: 1, minute: 30),
      boundary,
    );
    expect(at, DateTime(2026, 10, 15, 1, 30));
    expect(boundary.dayOf(at), day);
  });

  test('a midnight reset keeps every time on the same date', () {
    expect(
      instantOnLogicalDay(
        day,
        const TimeOfDay(hour: 1, minute: 30),
        const DayBoundary(resetHour: 0),
      ),
      DateTime(2026, 10, 14, 1, 30),
    );
  });
}

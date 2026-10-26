import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/features/habit/data/models/tracked_habit_model.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime(2026, 10, 16, 9);

  TrackedHabit tracked(Habit habit, {int? priceCents, int units = 20}) =>
      TrackedHabit(
        id: 1,
        habit: habit,
        priceCents: priceCents,
        unitsPerContainer: units,
        createdAt: createdAt,
      );

  group('unitPriceCents', () {
    test('divides the container price by its units', () {
      expect(
        tracked(Habit.vaping, priceCents: 1200, units: 30).unitPriceCents,
        40.0,
      );
    });

    test('is the price itself for a per-unit habit', () {
      expect(tracked(Habit.caffeine, priceCents: 450).unitPriceCents, 450.0);
    });

    test('is null without a price or for a habit with no cost', () {
      expect(tracked(Habit.vaping).unitPriceCents, isNull);
      expect(
        tracked(Habit.socialMedia, priceCents: 500).unitPriceCents,
        isNull,
      );
    });
  });

  test('copyWith can clear nullable fields', () {
    final habit = tracked(
      Habit.vaping,
      priceCents: 1200,
    ).copyWith(reason: () => 'Breathe', archivedAt: () => createdAt);

    expect(habit.reason, 'Breathe');
    expect(habit.isArchived, isTrue);
    expect(habit.copyWith(priceCents: () => null).priceCents, isNull);
    expect(habit.copyWith(archivedAt: () => null).isArchived, isFalse);
  });

  group('HabitRow mapping', () {
    HabitRow row(String kind, {String? name, String? unit}) => HabitRow(
      id: 3,
      kind: kind,
      customName: name,
      customUnit: unit,
      reason: 'For my lungs',
      priceCents: 1200,
      unitsPerContainer: 30,
      createdAt: createdAt,
    );

    test('a preset row maps to its preset', () {
      final habit = row('vaping').toEntity();

      expect(habit.id, 3);
      expect(habit.habit, Habit.vaping);
      expect(habit.reason, 'For my lungs');
      expect(habit.priceCents, 1200);
      expect(habit.unitsPerContainer, 30);
      expect(habit.createdAt, createdAt);
      expect(habit.archivedAt, isNull);
    });

    test('a custom row maps to Habit.custom', () {
      final habit = row('custom', name: 'Gaming', unit: 'hour').toEntity();

      expect(habit.habit, Habit.custom(name: 'Gaming', unit: 'hour'));
      expect(habit.habit.units, 'hours');
    });

    test('an unknown kind falls back to a custom habit', () {
      expect(row('gone', name: 'Old').toEntity().habit.kind, HabitKind.custom);
    });
  });
}

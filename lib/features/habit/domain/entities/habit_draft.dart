import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:meta/meta.dart';

/// A habit about to be tracked.
@immutable
class HabitDraft {
  const HabitDraft({
    required this.habit,
    this.reason,
    this.priceCents,
    this.unitsPerContainer = TrackedHabit.defaultUnitsPerContainer,
  });

  final Habit habit;
  final String? reason;
  final int? priceCents;
  final int unitsPerContainer;

  @override
  String toString() =>
      'HabitDraft(${habit.name}, $priceCents per $unitsPerContainer)';
}

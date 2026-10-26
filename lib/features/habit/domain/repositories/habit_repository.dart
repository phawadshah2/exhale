import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/features/habit/domain/entities/habit_draft.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';

abstract interface class HabitRepository {
  /// Habits not archived, oldest first.
  Stream<List<TrackedHabit>> watchActive();

  Future<Result<List<TrackedHabit>>> getActive();

  Future<Result<TrackedHabit>> add(
    HabitDraft draft, {
    required DateTime createdAt,
  });

  Future<Result<void>> update(TrackedHabit habit);

  /// Stops tracking [id]; its plans and logs are kept.
  Future<Result<void>> archive(int id, {required DateTime at});
}

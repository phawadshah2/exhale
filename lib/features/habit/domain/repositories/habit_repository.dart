import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/time/logical_day.dart';
import 'package:exhale/features/habit/domain/entities/habit_draft.dart';
import 'package:exhale/features/habit/domain/entities/price_history.dart';
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

  /// The habit's price points, oldest first.
  Stream<List<PricePoint>> watchPrices(int habitId);

  /// Changes the habit's price and records it from [day], so earlier days
  /// keep the price they had.
  Future<Result<void>> setPrice(
    int habitId, {
    required LogicalDay day,
    required int? priceCents,
    required int unitsPerContainer,
  });
}

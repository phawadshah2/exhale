import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';
import 'package:exhale/features/habit/domain/repositories/habit_repository.dart';
import 'package:exhale/features/habit/domain/usecases/add_habit.dart';
import 'package:exhale/features/habit/domain/usecases/archive_habit.dart';
import 'package:exhale/features/habit/domain/usecases/start_tracking.dart';
import 'package:exhale/features/habit/domain/usecases/update_habit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

final habitRepositoryProvider = Provider<HabitRepository>(
  (ref) => sl<HabitRepository>(),
);

final addHabitProvider = Provider<AddHabit>((ref) => sl<AddHabit>());

final updateHabitProvider = Provider<UpdateHabit>((ref) => sl<UpdateHabit>());

final archiveHabitProvider = Provider<ArchiveHabit>(
  (ref) => sl<ArchiveHabit>(),
);

final startTrackingProvider = Provider<StartTracking>(
  (ref) => sl<StartTracking>(),
);

/// Habits being tracked, oldest first.
final activeHabitsProvider = StreamProvider<List<TrackedHabit>>(
  (ref) => ref.watch(habitRepositoryProvider).watchActive(),
);

/// An active habit by id; null while loading or once it is archived.
final ProviderFamily<TrackedHabit?, int> habitProvider =
    Provider.family<TrackedHabit?, int>(
      (ref, id) => ref
          .watch(activeHabitsProvider)
          .value
          ?.where((habit) => habit.id == id)
          .firstOrNull,
    );

/// The oldest active habit.
final primaryHabitProvider = Provider<TrackedHabit?>(
  (ref) => ref.watch(activeHabitsProvider).value?.firstOrNull,
);

/// The only active habit; null with none or several.
final singleHabitProvider = Provider<TrackedHabit?>((ref) {
  final habits = ref.watch(activeHabitsProvider).value;
  return habits != null && habits.length == 1 ? habits.single : null;
});

final singleHabitIdProvider = Provider<int?>(
  (ref) => ref.watch(singleHabitProvider)?.id,
);

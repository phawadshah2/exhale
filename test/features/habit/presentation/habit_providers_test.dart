import 'package:exhale/core/di/injection_container.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/domain/entities/habit_draft.dart';
import 'package:exhale/features/habit/domain/usecases/add_habit.dart';
import 'package:exhale/features/habit/domain/usecases/archive_habit.dart';
import 'package:exhale/features/habit/presentation/providers/habit_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fixed_clock.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    await setUpTestDependencies(FixedClock(DateTime(2026, 10, 16, 15, 42)));
    container = ProviderContainer();
  });

  tearDown(() async {
    container.dispose();
    await InjectionContainer.reset();
  });

  Future<int?> singleHabitId() async {
    final sub = container.listen(activeHabitsProvider, (_, _) {});
    await container.read(activeHabitsProvider.future);
    await pumpEventQueue();
    final id = container.read(singleHabitIdProvider);
    sub.close();
    return id;
  }

  Future<void> add(Habit habit) => sl<AddHabit>()(HabitDraft(habit: habit));

  test('singleHabitIdProvider is null with no habit', () async {
    expect(await singleHabitId(), isNull);
  });

  test('singleHabitIdProvider is the id of the only active habit', () async {
    await add(Habit.vaping);

    expect(await singleHabitId(), 1);
  });

  test('singleHabitIdProvider is null with two habits, '
      'and back once one is archived', () async {
    await add(Habit.vaping);
    await add(Habit.caffeine);
    expect(await singleHabitId(), isNull);

    await sl<ArchiveHabit>()(1);
    expect(await singleHabitId(), 2);
  });

  test(
    'habitProvider finds an active habit and drops an archived one',
    () async {
      await add(Habit.vaping);
      final sub = container.listen(activeHabitsProvider, (_, _) {});
      await container.read(activeHabitsProvider.future);
      expect(container.read(habitProvider(1))?.habit, Habit.vaping);

      await sl<ArchiveHabit>()(1);
      await pumpEventQueue();
      expect(container.read(habitProvider(1)), isNull);
      sub.close();
    },
  );
}

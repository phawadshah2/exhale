import 'package:drift/drift.dart';
import 'package:exhale/core/data/local/database/app_database.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/domain/entities/habit_draft.dart';
import 'package:exhale/features/habit/domain/entities/tracked_habit.dart';

extension HabitRowMapper on HabitRow {
  TrackedHabit toEntity() => TrackedHabit(
    id: id,
    habit: _habit,
    reason: reason,
    priceCents: priceCents,
    unitsPerContainer: unitsPerContainer,
    createdAt: createdAt,
    archivedAt: archivedAt,
    quitAcknowledgedAt: quitAcknowledgedAt,
  );

  Habit get _habit {
    final habitKind = HabitKind.values.asNameMap()[kind];
    return habitKind == null || habitKind == HabitKind.custom
        ? Habit.custom(name: customName ?? '', unit: customUnit ?? '')
        : Habit.preset(habitKind);
  }
}

HabitsCompanion _habitColumns(Habit habit) {
  final isCustom = habit.kind == HabitKind.custom;
  return HabitsCompanion(
    kind: Value(habit.kind.name),
    customName: Value(isCustom ? habit.name : null),
    customUnit: Value(isCustom ? habit.unit : null),
  );
}

extension HabitDraftMapper on HabitDraft {
  HabitsCompanion toCompanion({required DateTime createdAt}) =>
      _habitColumns(habit).copyWith(
        reason: Value(reason),
        priceCents: Value(priceCents),
        unitsPerContainer: Value(unitsPerContainer),
        createdAt: Value(createdAt),
      );
}

extension TrackedHabitMapper on TrackedHabit {
  HabitsCompanion toCompanion() => _habitColumns(habit).copyWith(
    reason: Value(reason),
    priceCents: Value(priceCents),
    unitsPerContainer: Value(unitsPerContainer),
    archivedAt: Value(archivedAt),
    quitAcknowledgedAt: Value(quitAcknowledgedAt),
  );
}

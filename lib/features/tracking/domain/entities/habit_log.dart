import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:meta/meta.dart';

@immutable
class HabitLog {
  const HabitLog({
    required this.id,
    required this.loggedAt,
    required this.habitKind,
    this.trigger,
    this.note,
  });

  final int id;
  final DateTime loggedAt;

  /// The habit this was logged for, kept if the habit later changes.
  final HabitKind habitKind;
  final Trigger? trigger;
  final String? note;

  HabitLog copyWith({
    DateTime? loggedAt,
    Trigger? Function()? trigger,
    String? Function()? note,
    HabitKind? habitKind,
  }) => HabitLog(
    id: id,
    loggedAt: loggedAt ?? this.loggedAt,
    trigger: trigger != null ? trigger() : this.trigger,
    note: note != null ? note() : this.note,
    habitKind: habitKind ?? this.habitKind,
  );

  @override
  bool operator ==(Object other) =>
      other is HabitLog &&
      other.id == id &&
      other.loggedAt == loggedAt &&
      other.trigger == trigger &&
      other.note == note &&
      other.habitKind == habitKind;

  @override
  int get hashCode => Object.hash(id, loggedAt, trigger, note, habitKind);

  @override
  String toString() =>
      'HabitLog(#$id ${habitKind.name} at $loggedAt, $trigger)';
}

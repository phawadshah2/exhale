import 'package:exhale/features/tracking/domain/entities/trigger.dart';
import 'package:meta/meta.dart';

@immutable
class HabitLog {
  const HabitLog({
    required this.id,
    required this.habitId,
    required this.loggedAt,
    this.trigger,
    this.note,
  });

  final int id;
  final int habitId;
  final DateTime loggedAt;
  final Trigger? trigger;
  final String? note;

  HabitLog copyWith({
    DateTime? loggedAt,
    Trigger? Function()? trigger,
    String? Function()? note,
  }) => HabitLog(
    id: id,
    habitId: habitId,
    loggedAt: loggedAt ?? this.loggedAt,
    trigger: trigger != null ? trigger() : this.trigger,
    note: note != null ? note() : this.note,
  );

  @override
  bool operator ==(Object other) =>
      other is HabitLog &&
      other.id == id &&
      other.habitId == habitId &&
      other.loggedAt == loggedAt &&
      other.trigger == trigger &&
      other.note == note;

  @override
  int get hashCode => Object.hash(id, habitId, loggedAt, trigger, note);

  @override
  String toString() => 'HabitLog(#$id habit $habitId at $loggedAt, $trigger)';
}

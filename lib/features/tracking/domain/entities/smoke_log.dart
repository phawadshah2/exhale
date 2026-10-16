import 'package:exhale/features/tracking/domain/entities/smoke_trigger.dart';
import 'package:meta/meta.dart';

@immutable
class SmokeLog {
  const SmokeLog({
    required this.id,
    required this.loggedAt,
    this.trigger,
    this.note,
  });

  final int id;
  final DateTime loggedAt;
  final SmokeTrigger? trigger;
  final String? note;

  SmokeLog copyWith({
    DateTime? loggedAt,
    SmokeTrigger? Function()? trigger,
    String? Function()? note,
  }) => SmokeLog(
    id: id,
    loggedAt: loggedAt ?? this.loggedAt,
    trigger: trigger != null ? trigger() : this.trigger,
    note: note != null ? note() : this.note,
  );

  @override
  bool operator ==(Object other) =>
      other is SmokeLog &&
      other.id == id &&
      other.loggedAt == loggedAt &&
      other.trigger == trigger &&
      other.note == note;

  @override
  int get hashCode => Object.hash(id, loggedAt, trigger, note);

  @override
  String toString() => 'SmokeLog(#$id at $loggedAt, $trigger)';
}

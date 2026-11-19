import 'package:meta/meta.dart';

/// A log made outside the app (Siri, Shortcuts, the Action Button, a
/// control), waiting in the App Group queue to be stored.
@immutable
class QueuedLog {
  const QueuedLog({required this.id, required this.loggedAt});

  factory QueuedLog.fromJson(Map<String, Object?> json) => QueuedLog(
    id: json['id']! as String,
    loggedAt: DateTime.parse(json['loggedAt']! as String).toLocal(),
  );

  /// A UUID made by Swift; stored as the log's external id.
  final String id;
  final DateTime loggedAt;

  @override
  bool operator ==(Object other) =>
      other is QueuedLog && other.id == id && other.loggedAt == loggedAt;

  @override
  int get hashCode => Object.hash(id, loggedAt);

  @override
  String toString() => 'QueuedLog($id at $loggedAt)';
}

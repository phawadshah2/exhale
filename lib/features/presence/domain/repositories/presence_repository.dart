import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/features/presence/domain/activity_content.dart';
import 'package:exhale/features/presence/domain/presence_snapshot.dart';
import 'package:exhale/features/presence/domain/queued_log.dart';

/// The App Group files and the Live Activity, shared with Swift.
abstract interface class PresenceRepository {
  Future<Result<void>> writeSnapshot(PresenceSnapshot snapshot);

  /// Logs made outside the app, oldest first.
  Future<Result<List<QueuedLog>>> readQueue();

  /// Removes exactly [ids]; entries added since the read stay.
  Future<Result<void>> removeFromQueue(Set<String> ids);

  /// Starts the Live Activity, or updates the one running.
  Future<Result<void>> showActivity(ActivityContent content);

  Future<Result<void>> endActivity();

  /// Fires when Swift adds to the queue while the app runs.
  Stream<void> get queueChanged;
}

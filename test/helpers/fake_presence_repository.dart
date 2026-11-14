import 'dart:async';

import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/features/presence/domain/activity_content.dart';
import 'package:exhale/features/presence/domain/presence_snapshot.dart';
import 'package:exhale/features/presence/domain/queued_log.dart';
import 'package:exhale/features/presence/domain/repositories/presence_repository.dart';

/// In-memory App Group: records what the app sends and holds a queue.
class FakePresenceRepository implements PresenceRepository {
  final List<QueuedLog> queue = [];
  final List<PresenceSnapshot> snapshots = [];
  final List<ActivityContent> activities = [];
  final List<Set<String>> removals = [];
  int endedActivities = 0;

  /// Runs after each read, before the caller acts on it.
  void Function()? afterRead;

  final _queueChanged = StreamController<void>.broadcast();

  /// Appends [log] to the queue and signals, as Swift does.
  void enqueue(QueuedLog log) {
    queue.add(log);
    _queueChanged.add(null);
  }

  @override
  Future<Result<void>> writeSnapshot(PresenceSnapshot snapshot) async {
    snapshots.add(snapshot);
    return const Success(null);
  }

  @override
  Future<Result<List<QueuedLog>>> readQueue() async {
    final read = List<QueuedLog>.of(queue);
    afterRead?.call();
    return Success(read);
  }

  @override
  Future<Result<void>> removeFromQueue(Set<String> ids) async {
    removals.add(ids);
    queue.removeWhere((log) => ids.contains(log.id));
    return const Success(null);
  }

  @override
  Future<Result<void>> showActivity(ActivityContent content) async {
    activities.add(content);
    return const Success(null);
  }

  @override
  Future<Result<void>> endActivity() async {
    endedActivities++;
    return const Success(null);
  }

  @override
  Stream<void> get queueChanged => _queueChanged.stream;
}

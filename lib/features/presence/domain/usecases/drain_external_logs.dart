import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/core/domain/usecase/usecase.dart';
import 'package:exhale/features/presence/domain/queued_log.dart';
import 'package:exhale/features/presence/domain/repositories/presence_repository.dart';
import 'package:exhale/features/tracking/domain/repositories/habit_log_repository.dart';

/// Stores the logs made outside the app for the habit with the given id,
/// then removes exactly those from the queue. An entry already stored (by its
/// id) is removed, never inserted again, so a drain cut short or run twice
/// cannot double a log. Returns how many logs were inserted.
class DrainExternalLogs implements UseCase<int, int> {
  const DrainExternalLogs(this._logs, this._presence);

  final HabitLogRepository _logs;
  final PresenceRepository _presence;

  @override
  Future<Result<int>> call(int habitId) async {
    final read = await _presence.readQueue();
    if (read case FailureResult(:final failure)) return FailureResult(failure);
    final queue = (read as Success<List<QueuedLog>>).value;
    if (queue.isEmpty) return const Success(0);

    final ids = {for (final log in queue) log.id};
    final stored = await _logs.storedExternalIds(ids);
    if (stored case FailureResult(:final failure)) {
      return FailureResult(failure);
    }
    final done = {...(stored as Success<Set<String>>).value};

    var inserted = 0;
    for (final log in queue) {
      if (!done.add(log.id)) continue;
      final added = await _logs.addLog(
        habitId: habitId,
        loggedAt: log.loggedAt,
        externalId: log.id,
      );
      if (added case FailureResult(:final failure)) {
        return FailureResult(failure);
      }
      inserted++;
    }

    final removed = await _presence.removeFromQueue(ids);
    if (removed case FailureResult(:final failure)) {
      return FailureResult(failure);
    }
    return Success(inserted);
  }
}

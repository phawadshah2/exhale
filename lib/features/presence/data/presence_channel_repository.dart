import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';
import 'package:exhale/features/presence/domain/activity_content.dart';
import 'package:exhale/features/presence/domain/presence_snapshot.dart';
import 'package:exhale/features/presence/domain/queued_log.dart';
import 'package:exhale/features/presence/domain/repositories/presence_repository.dart';
import 'package:flutter/services.dart';

/// [PresenceRepository] over the `exhale/presence` channel (AppDelegate and
/// the widget extension share the App Group files).
class PresenceChannelRepository implements PresenceRepository {
  PresenceChannelRepository([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel('exhale/presence') {
    _channel.setMethodCallHandler(_onCall);
  }

  final MethodChannel _channel;
  final _queueChanged = StreamController<void>.broadcast();

  static const _source = 'PresenceChannelRepository';

  @override
  Future<Result<void>> writeSnapshot(PresenceSnapshot snapshot) => _guard(
    () => _channel.invokeMethod<void>(
      'writeSnapshot',
      jsonEncode(snapshot.toJson()),
    ),
  );

  @override
  Future<Result<List<QueuedLog>>> readQueue() => _guard(() async {
    final json = await _channel.invokeMethod<String>('readQueue');
    if (json == null || json.isEmpty) return const <QueuedLog>[];
    return [
      for (final entry in jsonDecode(json) as List<Object?>)
        QueuedLog.fromJson((entry! as Map).cast<String, Object?>()),
    ];
  });

  @override
  Future<Result<void>> removeFromQueue(Set<String> ids) => _guard(
    () => _channel.invokeMethod<void>('removeFromQueue', ids.toList()),
  );

  @override
  Future<Result<void>> showActivity(ActivityContent content) => _guard(
    () => _channel.invokeMethod<void>(
      'showActivity',
      jsonEncode(content.toJson()),
    ),
  );

  @override
  Future<Result<void>> endActivity() =>
      _guard(() => _channel.invokeMethod<void>('endActivity'));

  @override
  Stream<void> get queueChanged => _queueChanged.stream;

  Future<void> _onCall(MethodCall call) async {
    if (call.method == 'queueChanged') _queueChanged.add(null);
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success<T>(await action());
    } on Exception catch (error, stackTrace) {
      developer.log(
        'Presence channel call failed',
        name: _source,
        error: error,
        stackTrace: stackTrace,
      );
      return FailureResult<T>(const StorageFailure());
    }
  }
}

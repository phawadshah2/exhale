import 'dart:developer' as developer;

import 'package:exhale/core/domain/error/failure.dart';
import 'package:exhale/core/domain/result/result.dart';

/// Runs a storage call and turns any exception into a [StorageFailure].
Future<Result<T>> guardStorage<T>(
  String source,
  Future<T> Function() action,
) async {
  try {
    return Success<T>(await action());
  } on Exception catch (error, stackTrace) {
    developer.log(
      'Storage operation failed',
      name: source,
      error: error,
      stackTrace: stackTrace,
    );
    return FailureResult<T>(const StorageFailure());
  }
}

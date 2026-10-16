import 'package:exhale/core/domain/error/failure.dart';

String failureMessage(Failure failure) => switch (failure) {
  ValidationFailure(:final message) => message,
  StorageFailure() => "Couldn't save that. Please try again.",
  NotFoundFailure() => 'That entry no longer exists.',
};

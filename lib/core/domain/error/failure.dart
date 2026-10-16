sealed class Failure {
  const Failure();
}

final class ValidationFailure extends Failure {
  const ValidationFailure(this.message);
  final String message;
}

final class StorageFailure extends Failure {
  const StorageFailure();
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure();
}

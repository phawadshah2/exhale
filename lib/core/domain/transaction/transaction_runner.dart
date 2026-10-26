/// Runs several storage calls as one: if the action throws, none of them
/// stay.
abstract interface class TransactionRunner {
  Future<T> run<T>(Future<T> Function() action);
}
